data "aws_iam_policy_document" "ecs_task_execution_role" {
  version = "2012-10-17"
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

#create ECS task execution role

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json
}

#ECS task execution role policy attachment

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


data "template_file" "app"{
    template = file("./templates/app.json")

    vars = {
        game_name = var.game_name
        game_image = var.game_image
        game_cpu = var.game_cpu
        game_memory = var.game_memory
        game_port = var.game_port
        
        aws_region = var.region
    }
}

data "template_file" "appdup"{
    template = file("./templates/appdup.json")

    vars = {
        game_name = var.game_name
        game_image = var.game_image
        game_cpu = var.game_cpu
        game_memory = var.game_memory
        game_port = var.game_port
        
        aws_region = var.region
    }
}

data "template_file" "dru"{
  template = file("./templates/container2.json")
  vars = {
    drupal_name = var.drupal_name
        drupal_image = var.drupal_image
        # drupal_cpu = var.drupal_cpu
        drupal_memory = var.drupal_memory
        drupal_port = var.drupal_port
        aws_region = var.region
  }
}

locals{
  cot = {
      "name" : var.drupal_name,
      "image" : var.drupal_image,
      
     "memory": var.drupal_memory,
      "networkMode" : "awsvpc",
      "portMappings" : [
        {
          "containerPort" : var.drupal_port
        }
      ] 
      
   }
   final = format("[%s,%s]",data.template_file.appdup.rendered,data.template_file.dru.rendered)
   
}

resource "aws_ecs_task_definition" "ecs_task_def" {
    family = "BT"
    execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
    network_mode = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu = 256
    memory = 512
    container_definitions = format("[%s,%s]",data.template_file.appdup.rendered,data.template_file.dru.rendered)#data.template_file.app.rendered
}

output "kii" {
  value = local.final
}

