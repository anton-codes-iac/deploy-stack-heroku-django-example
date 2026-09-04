# --- Worker ECS Task Definition ---
resource "aws_ecs_task_definition" "worker" {
  family                   = "deploy-stack-heroku-django-example-worker-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = "deploy-stack-heroku-django-example-worker-container"
      image     = "${aws_ecr_repository.app.repository_url}:latest"
      essential = true

      environment = [
        { "name": "NODE_ENV", "value": "production" },
        
      ]

      secrets = concat(
        [
          for key in local.secret_keys : {
            name      = key
            valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:${key}::"
          }
        ],
        [
          
        ]
      )

      command = ["celery","-A","core","worker","-l","info"]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app_logs.name
          "awslogs-region"        = "us-east-2"
          "awslogs-stream-prefix" = "worker" # Isolates worker logs from web logs
        }
      }
    }
  ])
}

# --- Worker ECS Service ---
# Notice there is NO load_balancer block. This service is strictly private.
resource "aws_ecs_service" "worker" {
  name            = "deploy-stack-heroku-django-example-worker-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.worker.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true 
  }
}