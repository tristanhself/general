// AWS ECS Cluster, Task Roles, Task Definition and Service Definition -----------------------------------------------------------------------------------------------------------------

# Creates the AWS ECS Cluster, Task Roles (i.e. the permissions of ECS and the Tasks), Task Definitions (i.e. deploys the containers) and defines the Service (through which the 
# application is accessed.)

# AWS ECS "Execution Role" -------------------------------------------------------------------------------------------------------------------------------------------------------------
# Purpose: Execution Role is used by the ECS Agent to make AWS API calls on the behalf of the user.

# Define the Role.
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

# Define who/what can use the Role.
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Define what the role can do.
resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
# Rather than specifying the role manually, we are using a pre-existing role with the necessary actions we need:
# ecr:GetAuthorizationToken
# ecr:BatchCheckLayerAvailability
# ecr:GetDownloadUrlForLayer"
# ecr:BatchGetImage
# logs:CreateLogStream
# logs:PutLogEvents

# AWS ECS "Task Role" ----------------------------------------------------------------------------------------------------------------------------------------------------------------
# Purpose: Task Role grants permissions specifically to the tasks, e.g. if a running task needs to access another AWS resource, e.g. a database.

# We don't need a task role for this use case, the tasks (containers) don't need to access anything else.

# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# AWS ECS Cluster
resource "aws_ecs_cluster" "example" {
  name = "fargate-cluster"
}

# ECS Task Definition (Container)
resource "aws_ecs_task_definition" "example" {
  family                   = "fargate-task"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn # Execution Role is used by the ECS Agent to make AWS API calls on the behalf of the user.
  # task_role_arn          = aws_iam_role.ecs_task_role.arn # Task Role grants permissions specifically to the tasks, e.g. if a running task needs to access another AWS resource.
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # Adjust based on your needs
  memory                   = "512" # Adjust based on your needs

  container_definitions = jsonencode([{
    name      = "my-container"
    #image     = "nginx" # Replace with your container image
    image     = var.ecrimageuri
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }]
  }])
}

# ECS Service Definition
resource "aws_ecs_service" "example" {
  name            = "fargate-service"
  cluster         = aws_ecs_cluster.example.id
  task_definition = aws_ecs_task_definition.example.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    container_name   = "my-container"
    container_port   = 80
  }

  network_configuration {
    subnets          = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  depends_on = [
    aws_lb_listener.http
  ]
}