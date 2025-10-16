# Convertr Take Home Task

## Architecture Diagram

![Architectural diagram of the solution.](/Resources/Convertr.drawio.png)

## High-Level Overview



## CICD Flow

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