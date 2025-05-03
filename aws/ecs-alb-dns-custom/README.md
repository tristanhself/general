# Amazon Elastic Container Service (ECS) with Application Load Balancer and DNS (Route53)

The Amazon Elastic Container Service (ECS), specifically Fargate allows you to run containers on an ad-hoc basis. 

The following guide assumes you have already deployed an Amazon Elastic Container Registry (ECR), built your image, pushed it to the ECR and have obtained the Repository URI.

## Step 1 - Update Terraform Variables 

There are three variables to update within the *variables.tf* file:

* route53zone - The AWS Route53 Hosted Zone ID which you can obtain from the AWS console, obviously you need to have the domain already present as an AWS Route53 Hosted Zone.
* domainname - The domain name (excluding sub-domain) that your application will be deployed at, this assumes you already have the domain in an AWS Route53 Hosted Zone.
* ecrimageuri - The Amazon Elastic Container Registry (ECR) URI which you can obtain from the AWS console for the image you wish to deploy from the repository.

Update the variables by updating the "default" value within the *variables.tf* file.

## Step 2 - Deploy Terraform

```
terraform apply [--auto-approve]
```

## Step 3 - Verify Behaviour

Once deployed, the Terraform provides some Outputs. however all you need is to access your application at the domain name you entered, e.g. https://www.mydomain.com or https://mydomain.com, the ALB automatically redirects from HTTP to HTTPS if required.

Perform whatever tests you require.

## Step 4 - Clean-Up

To clean up, you need remove your ECS cluster, ALB by running a Terraform destroy, bear in mind that the image(s) stored in the Amazon Elastic Container Registry (ECR) are not removed, if you've deployed the ECR separately, you'll need to remove this separately.

As we created using Terraform you can remove with Terraform thusly:
```
terraform destory [--auto-approve]
```

As you can see it is fairly simple to deploy a resilient container based workload and publish it to the Internet, obviously there is lots more that can be done to improve this deployment, but this provides you with the basis from which to build.

# Terraform and Configuration Explaination

Let's deep dive into each of the sections of the configuration, so we can understand what is being done at each stage. We'll not include the Terraform provider within the explaination as it is hoped you're aware of this and how they work already.

## main.tf - VPC, Subnets, IGW, Route Table(s) and Security Group

The "main.tf" file contains the creation of the VPC, followed by creation of two Subnets A and B which are created as "private subnets". The VPC then has an Internet Gateway created, with a RouteTable and default Routes attached, so the VPC and the subnets have a direct Internet connection.

## ecs.tf - AWS ECS Cluster, Task Roles, Task Definition and Service Definition

Creates the AWS ECS Cluster, Task Roles (i.e. the permissions of ECS and the Tasks), Task Definitions (i.e. deploys the containers) and defines the Service (through which the application is accessed.)

### AWS ECS Execution Roles

The Execution Role is used by the ECS Agent to make AWS API calls on the behalf of the user.

We first define the role with:
```
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}
```

We then create an Assume Role Policy, which defines who (or what if the principal is a service) can use the role we just created.
```
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
```

Now we have defined the role and who/what can use the role we need to define what the role canm actually do, rather than specifying the Role Action Policy manually, we are using a pre-existing Policy with the necessary actions we need: ecr:GetAuthorizationToken, ecr:BatchCheckLayerAvailability, ecr:GetDownloadUrlForLayer, ecr:BatchGetImage, logs:CreateLogStream, logs:PutLogEvents. And one already exists for this purpose: AmazonECSTaskExecutionRolePolicy.

```
resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
```

### AWS ECS Task Roles

Task Role grants permissions specifically to the tasks, e.g. if a running task needs to access another AWS resource, e.g. a database. We don't need a task role for this use case, the tasks (containers) don't need to access anything else.

### AWS ECS Cluster, ECS Task Definition and ECS Service Definition

We now need to define the AWS ECS cluster.

```
resource "aws_ecs_cluster" "example" {
  name = "fargate-cluster"
}
```

Once defined we can now define the ECS Task, within this we are specifying the size of the containers, and also which image we are wanting to use for the task, here we specify the Repository URI where the image resides.

```
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
```

Finally we define the ECS Service Definition, this dectates how many containers are deployed, which subnets they will be deployed to, along with the security group to restrict access to them.

It also binds the Load Balancer Target Group to the ECS Service, so the Load Balancer will direct requests to the running container ports.

```
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
    assign_public_ip = false
  }

  depends_on = [
    aws_lb_listener.http
  ]
}
```

## alb.tf - Application Load Balancer

We define the Application Load Balancer (ALB), which consists of these main components:

* Application Load Balancer (ALB) Definition - The actual definition of the load balancer, which includes the security group that restricts access to it.
* Application Load Balancer (ALB) Target Group - The definition of the target group which links the listeners, i.e. the things that the end user will hit when connecting and the, in this case containers that the connections will be redirected to.
* Application Load Balancer (ALB) Listener (HTTP) - The definition of the listener that the end user will hit, this is the HTTP one which redirets to HTTPS.
* Application Load Balancer (ALB) Listener (HTTPS) - The definition of the listener that the end user will hit, this is the HTTPS one which has a certificate binding and directs the connections to the Target Group, which in turn goes to the containers running in AWS ECS.

```
# Application Load Balancer (ALB) Definition
resource "aws_lb" "app_lb" {
  name               = "fargate-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets            = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "fargate-alb"
  }
}

# ALB Target Group
resource "aws_lb_target_group" "ecs_target_group" {
  name     = "ecs-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Name = "ecs-target-group"
  }
}

# ALB Listener (HTTP) with Redirect to HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port = 443
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ALB Listener (HTTPS)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn = aws_acm_certificate.example.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
  }
}
```

## dnscert.tf - DNS Record and certificate

These define the DNS records automatically, which includes defining the following:

* www.domain.com CNAME record which points at the Application Load Balancer (ALB).
* domain.com A record which is a special Apex A record which points at the Application Load Balancer (ALB).

The Terraform also creates the Amazon Certificate Manager (ACM) certificate automatically, it also inserts the validation record into the DNS zone automatically, so it is ready to be assigned to the load balancer.