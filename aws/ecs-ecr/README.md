# Amazon Container Registry (ECR)

The Amazon Container Registry (ECR) allows you to store the images within the cloud, for the purposes of this example we'll use a simple container using a Dockerfile
that creates an Apache web server that says "Hello World!". 

## Step 1 - Deploy Terraform

You first need to run the Terraform which creates the Amazon Container Registry (ECR), the output of this command provides you with the Elastic Container Registry Repository URI, you'll
then require this for once you have built your image and need to push it to the ECR.

```
terraform apply [--auto-approve]
```

## Step 2 - Create Docker File

We first need to create the Dockerfile, so touch a file to get started.
```
touch Dockerfile
```
Create the Dockerfile with the following contents:
```
FROM public.ecr.aws/amazonlinux/amazonlinux:latest

# Update installed packages and install Apache
RUN yum update -y && \
 yum install -y httpd

# Write hello world message
RUN echo 'Hello World!' > /var/www/html/index.html

# Configure Apache
RUN echo 'mkdir -p /var/run/httpd' >> /root/run_apache.sh && \
 echo 'mkdir -p /var/lock/httpd' >> /root/run_apache.sh && \
 echo '/usr/sbin/httpd -D FOREGROUND' >> /root/run_apache.sh && \
 chmod 755 /root/run_apache.sh

EXPOSE 80

CMD /root/run_apache.sh```

```

## Step 3 - Build the Image

Now we can build the image, we'll then tag the image as we go, in the example below i'm tagging the image as "hello-world:1.0", but i've shown (and is the case through out this documentation) how you can tag another version of the image, e.g. version 2. 
```
docker build -t hello-world:1.0 .
docker build -t hello-world:2.0 .
```

(Optional) If you want you can run the image locally to test it works as expected.
```
docker run -t -i -p 80:80 hello-world:1.0
```

## Step 4 - Tag the Image

We'd have already deployed the AWS ECR, and we have the URI from the output of the Terraform. i.e. 349755379714.dkr.ecr.eu-west-2.amazonaws.com/hello-world, so now we need to tag the image with the Repository URI. Again two commands are given to show how you'd tag version 2 as well.
```
docker tag hello-world:1.0 349755379714.dkr.ecr.eu-west-2.amazonaws.com/hello-world:1.0
docker tag hello-world:2.0 349755379714.dkr.ecr.eu-west-2.amazonaws.com/hello-world:2.0
```

## Step 5 - Obtain AWS ECR Password and Login

To be able to push the image, we first need to obtain the AWS ECR password, then we can pipe this into the Docker login along with your correct "Region" and the AWS ECR Repository URI.
```
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin 349755379714.dkr.ecr.eu-west-2.amazonaws.com/hello-world
```
You should see "Login Succeeeded"

## Step 6 - Push the Image to Amazon Elastic Container Registry Repository

You can now push the image, using the following commands, we'll then be able to obtain the Image URI which you'll need if/when you wish to lauch these images (containers) within AWS Elastic Container Service etc. 
```
docker push 349755379714.dkr.ecr.eu-west-2.amazonaws.com/hello-world:1.0
docker push 349755379714.dkr.ecr.eu-west-2.amazonaws.com/hello-world:2.0
```

You should now see the image has been uploaded to the Amazon AWS Elastic Container Registry, using the web console you can obtain the Image URI which you'll need to be able to launch the image/container on AWS ECS, Fargate, EKS etc. 

## Step 7 - Clean-Up

To clean up, you need remove your repository to ensure you're not charged for the storage, the example repo is called: "hello-world".

Note that you need to have deleted all images before you can delete the AWS ECR.

As we created using Terraform you can remove with Terraform thusly:
```
terraform destory [--auto-approve]
```

If you'd like to manually remove it you can use this, however if you are managing with Terraform this is not recommended.

```
aws ecr delete-repository --repository-name ecr-repo --region region --force
```

## Step 8 - Conclusion

That concludes the illustration of the build and push of an image. It is possible to automate the creation of the Repository, the build of the image and the push, however this is beyond the scope of this document, see below for more details.

# Automate Image Build and Push with Terraform

It is possible to automate the image build, tagging and push within Terraform by using a "local-exec" definition: https://www.linkedin.com/pulse/how-upload-docker-images-aws-ecr-using-terraform-hendrix-roa, and example is given below.

```
resource "null_resource" "docker_packaging" {
	
	  provisioner "local-exec" {
	    command = <<EOF
	    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com
	    gradle build -p noiselesstech
	    docker build -t "${aws_ecr_repository.noiselesstech.repository_url}:latest" -f noiselesstech/Dockerfile .
	    docker push "${aws_ecr_repository.noiselesstech.repository_url}:latest"
	    EOF
	  }
	

	  triggers = {
	    "run_at" = timestamp()
	  }
	

	  depends_on = [
	    aws_ecr_repository.noiselesstech,
	  ]
} 
```

# Useful Links

* https://channaly.medium.com/how-to-add-attach-multiple-acm-certificates-to-an-aws-load-balancer-in-terraform-1e497d20eb21
* https://towardsaws.com/deploy-a-docker-image-to-aws-elastic-container-service-using-terraform-68767113f26b
* https://www.apprunnerworkshop.com/getting-started/
* https://spacelift.io/blog/terraform-ecs
* https://headforthe.cloud/article/managing-acm-with-terraform/
* https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-container-image.html
* https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-container-image.html
* https://snehalchaure.medium.com/deploy-a-dockerised-app-on-amazon-elastic-container-service-ecs-using-terraform-e7c92d9814ee