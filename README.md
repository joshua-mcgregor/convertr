# Convertr Take Home Task

## Architecture Diagram

![Architectural diagram of the solution.](/Resources/Convertr.drawio.png)

## High-Level Overview

### Overall User Flow

1. User makes an API request to API hosted by CloudFront distibution.
2. Attached WAF performs security checks and filters requests.
3. Valid requests are routed to API Gateway hosted in eu-west-2 region.
4. API Gateway passes request to Cognito for authorisation handling.
5. Cognito validates user JWT.
6. Valid user is redirected to Upload Lambda.
7. Upload Lambda processes file upload and validates it is an image.
8. If it's an image, file is stored in s3 and 200 request is returned with filename.
9. If it's not an image, 400 is returned.

### CICD Flow

There is a CICD flow which triggers on a push to the main branch only. This flow consists of the following steps:

| Step | Purpose |
| --- | --- |
| Checkout Code | Clones the git repository in to the current workspace. |
| Setup Python | Installs python and dependencies. |
| Install Poetry & Plugins | Installs poetry and needed plugins. |
| Install Test Dependencies | Installs the full depencies of the application including test dependencies. | 
| Run Unit Tests | Runs the unit test suite of the application. |
| Install Production Dependencies | Install only the production dependencies to be zipped for the lambda package. | 
| Copy Lambda Code | Moves to the source code to be packaged for the lambda. | 
| Bundle Lambda | Packages the lambda as a zip to be used in our terraform logic. | 
| Configure AWS Credentials | Configures the local AWS environment. |
| Set GIT_COMMIT Variable | Set a local env variable so we can access the git commit sha. |
| Setup Terraform | Installs terraform and required dependencies. |
| Terraform Init | Initialises the terraform project. |
| Terraform Format | Checks the format is valid. |
| Terraform Validate | Checks the terraform files are valid. |
| Terraform Apply | Deploys the infrastructure if there are any changes and captures the outputs. | 
| Export Terraform Outputs to ENV | Exports the outputs from the terraform apply to the local environment. | 
| Get Cognito Token | Gets a Cognito JWT for our test user to be able to run E2E tests. |
| Run E2E Tests | Runs the End to End test suite hitting the deployed CloudFront distibution endpoint. | 

## How to run Lambda unit tests

```
poetry run pytest tests/unit/
```

## Additional Resources

As per the requirement, all resources specified in the task are created and deployed through terraform (IAC). However, there are some resources created outside of this project as support for the project. This includes the CICD role attached to GitHub, the terraform statefile bucket (as this is needed to allow terraform config to run) and the bucket policy for said bucket. The configurations for these items can be found in the `Resources` directory.

This directory also contains an SCP policy not applied to my personal account which would limit the scope and reduce the blast radius for some of the policies defined in this project.

## Security Considerations and Current Risks

### IAM Blast Radius

There is a CICD role which can be assumed by GitHub to enable GitHub actions to deploy terraform in to the AWS account. WHERE POSSIBLE, this role is locked down to specific resources required by the project itself and scoped appropriately so it can only create, modify and delete it's own project resources. These resources are:

| IAM Permission | Resource / Scope | Impact / Risk |
| --- | --- | --- |
| S3 | arn:aws:s3:::convertr-picture-bucket-eu-west-2 | Can perform a variety of operations on the convertr-picture-bucket-eu-west-2 only. |
| Lambda | arn:aws:lambda:eu-west-2:278309669918:function:lambda-convertr-* | Can create, modify and get functions with the associated resource. |
| API Gateway | * | AWS support for resource scoping against API Gateway is very limited and as such the blast radius is fairly large. You could in theory modify any API Gateway config using this role. |
| EC2 | * | AWS requires * for creation of VPCs, subnets etc as those resources don't exist or aren't named. You can scope deletion and modification to specific ARNs but this is manually intensive. This means the current blast radius impact is high as this role could create, modify or delete any VPCs, subnets, Security Groups etc. |
| IAM | arn:aws:iam::278309669918:role/iam-convertr-lambda-* | Can create, pass and assume IAM roles with the scoped ARN. |
| CloudWatch | arn:aws:logs:eu-west-2:278309669918:log-group:/aws/lambda/* | Can create, put and describe new log streams and log events for lambdas. |

However, there are still aspects of risk with this role and in a real world project I would not allow a developer to create or modify these resources within an application project. The areas of risk are:

| Risk | Impact | Remediation |
| --- | --- | --- |
| iam:CreateRole | Even though this is scoped in the CICD role, this current permission will allow a user to create an IAM role of their own design and could be used maliciously. This is currently required for the Lamba creation to attach an execution rule as per the requirement of the task.  | In a real life scenario, I would potentially have a separate managed pipeline for IAM role creation. This would be a managed service that would enable us to perform additional checks and validations on IAM role creation. Developers could then use these approved IAM roles in their own application development without additional blast radius on their IAM role. |
| VPC Config | VPC config is currently unscoped and within the same project as this application.  | In a real life scenario, I would potentially have a separate repository for application development and AWS infrastructure config. VPCs and all associated infrastructure would be managed separately. |
| CICD role | The CICD role only works on the main branch of this specific repository. This current project is wide reaching and as such the blast radius is fairly large. | I would scope multiple CICD roles for different responsibilities based on what permissions each repository would need. |

#### Reducing risk

In order to reduce the above risks with the IAM role, there is an SCP rule inside the `Resources` directory which prevents other IAM roles from being able to access a variety of permissions across the AWS environment. Only the whitelisted rules in the SCP `NotAction` block would be allowed. This isn't implemented as defined in my personal AWS environment as I have other resources running.

## Design Considerations And Potential Improvements

### Lambda and API Gateway Limits

Lambda and API Gateway have very small limits for request and response sizes (6mb to 10mb). If you needed to upload large image files, the best way to do this would either be pre-signed URLS (not a very friendly user experience) or run the tasks on a larger compute such as ECS.

### File Type Validation

There are stronger ways of validating the file type but for ease of implementation and time constraints I settled on the Pillow library. Other methods would require more dependency management through something like lambda layers.

### API Authorisation

This application uses Cognito for authentication of the API. There isn't a method outside of automation exposed for adding new users to the user pool. Currently, only one user is created and that is the test-user as part of the CICD execution. One improvement would be to implement an OAuth flow and callback to the API.

### Resiliency

This application exists primarily in one region. If you wanted to ensure a high uptime with high resiliency, an active-active multi-region approach would be much more resilient but would need to consider how Cognito interacts as that is single region. You could replicate the data between regions but that would need to be handled independently and introduces risk. An alternative would be an external IDP. Replication between buckets would be straight forward but could be expensive depending on expected load. One option is to use lifecycle policies to move old items in to archival storage to reduce cost.

### Python vs Containerisation

As this was a simple use case, I decided to simply use python scripts. If this was a larger application, I may consider using docker to ensure portability of the application between environments. Lambda has good docker integration but the size of the image in addition to the cold start times can be a downside.

### CICD

There's a lot to go after in a full CICD pipeline. Different environments, different behaviours for different branches. One thing that would be good would be to enable testing on branches. This would give reassurance prior to a merge that your PR is behaving as expected.

### VPC Config

Currently there are no NACL rules set up for the subnet. As this is only a lambda, it cannot be directly accessed through the internet regardless. If there were other resources we needed to protect, NACL rules restricting traffic from outside the VPC would be advisable. API Gateway is already public facing so isn't impacted by either SGs or NACL rules.

