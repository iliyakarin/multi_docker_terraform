provider "aws" {
  region     = "eu-west-2"
  access_key = ""
  secret_key = ""
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_elastic_beanstalk_application" "multi-docker" {
  name        = "multi-docker"
  tags        = {
    name = "mydocker"
  }
}

resource "aws_elastic_beanstalk_environment" "env-multi-docker" {
  name                 = "Multidocker-env"
  application          = aws_elastic_beanstalk_application.multi-docker.name
  solution_stack_name  = "64bit Amazon Linux 2018.03 v2.25.0 running Multi-container Docker 19.03.13-ce (Generic)"
  tier                 = "WebServer"
  setting {
        namespace = "aws:autoscaling:launchconfiguration"
        name      = "IamInstanceProfile"
        value     = "aws-elasticbeanstalk-ec2-role"
      }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "REDIS_HOST"
    value     = aws_elasticache_cluster.multi-docker-elasticache.cache_nodes.0.address
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "REDIS_PORT"
    value     = "6379"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PGUSER"
    value     = "postgres"
  }
  setting {
  namespace = "aws:elasticbeanstalk:application:environment"
  name      = "PGPASSWORD"
  value     = aws_db_instance.multi-docker-postgres.password
  }
  setting {
  namespace = "aws:elasticbeanstalk:application:environment"
  name      = "PGHOST"
  value     = aws_db_instance.multi-docker-postgres.address
  }
  setting {
  namespace = "aws:elasticbeanstalk:application:environment"
  name      = "PGDATABASE"
  value     = aws_db_instance.multi-docker-postgres.name
  }
  setting {
  namespace = "aws:elasticbeanstalk:application:environment"
  name      = "PGPORT"
  value     = "5432"
  }
  setting {
  namespace = "aws:autoscaling:launchconfiguration"
  name      = "SecurityGroups"
  value     = aws_security_group.multi-docker.name
  }
}

resource "aws_db_instance" "multi-docker-postgres" {
  allocated_storage       = 20
  identifier              = "multi-docker-postgres"
  storage_type            = "gp2"
  engine                  = "postgres"
  instance_class          = "db.t2.micro"
  name                    = "postgres"
  username                = "postgres"
  password                = "postgres_password"
  skip_final_snapshot     = true
  backup_retention_period = 0
  vpc_security_group_ids  = [aws_security_group.multi-docker.id]
}

resource "aws_elasticache_cluster" "multi-docker-elasticache" {
  cluster_id           = "multi-docker-elasticache"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis3.2"
  engine_version       = "3.2.10"
  port                 = 6379
  snapshot_retention_limit = 0
  security_group_ids   = [aws_security_group.multi-docker.id]
}

resource "aws_security_group" "multi-docker" {
  name        = "multi-docker"
  description = "multi-docker"

  dynamic "ingress" {
    for_each = ["80", "443"]
    content{
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ingress {
    from_port   = 5432
    to_port     = 6379
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "multi-docker"
  }
}
