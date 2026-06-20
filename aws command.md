aws eks list-clusters --region ap-south-1

aws eks describe-cluster \
  --name java-spring-eks \
  --region ap-south-1 \
  --query "cluster.resourcesVpcConfig.vpcId" \
  --output text


aws eks describe-cluster \
  --name java-spring-eks \
  --region ap-south-1 \
  --query "cluster.resourcesVpcConfig.subnetIds"


harish@Harish:~/employeeBudget-Java-aws/rpsp_infra/iac/terraform$ aws ec2 describe-subnets \
  --subnet-ids subnet-05fa07de18677174e subnet-05e66df01fb3253ce \
  --region ap-south-1 \
  --query "Subnets[*].[SubnetId,AvailabilityZone,MapPublicIpOnLaunch]" \
  --output table
------------------------------------------------------
|                   DescribeSubnets                  |
+---------------------------+---------------+--------+
|  subnet-05fa07de18677174e |  ap-south-1a  |  False |
|  subnet-05e66df01fb3253ce |  ap-south-1b  |  False |
+---------------------------+---------------+--------+
harish@Harish:~/employeeBudget-Java-aws/rpsp_infra/iac/terraform$

If MapPublicIpOnLaunch = True → Public subnet
If MapPublicIpOnLaunch = False → Private subnet


aws eks describe-cluster \
  --name java-spring-eks \
  --region ap-south-1 \
  --query "cluster.resourcesVpcConfig.securityGroupIds"

harish@Harish:~/employeeBudget-Java-aws/rpsp_infra/iac/terraform$ aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=vpc-0714e469a68ae1721" \
  --region ap-south-1 \
  --query "SecurityGroups[*].[GroupId,GroupName]" \
  --output table
----------------------------------------------------------------------
|                       DescribeSecurityGroups                       |
+-----------------------+--------------------------------------------+
|  sg-0f02d2205e2d86524 |  eks-cluster-sg-java-spring-eks-568633688  |
|  sg-0fe408481fc8b427d |  java-spring-sg                            |
|  sg-0379f88c8e741260e |  default                                   |
+-----------------------+--------------------------------------------+
harish@Harish:~/employeeBudget-Java-aws/rpsp_infra/iac/terraform$




Secrets Manager:
--------------------------------------
aws secretsmanager create-secret \
  --name db-credentials \
  --description "Postgres credentials for Terraform batch job" \
  --secret-string '{"username":"postgres","password":"ChangeMeStrong123!"}' \
  --region ap-south-1


harish@Harish:~/employeeBudget-Java-aws/rpsp_infra/iac/terraform$ aws secretsmanager create-secret \
  --name db-credentials \
  --description "Postgres credentials for Terraform batch job" \
  --secret-string '{"username":"postgres","password":"ChangeMeStrong123!"}' \
  --region ap-south-1
{
    "ARN": "arn:aws:secretsmanager:ap-south-1:495013583028:secret:db-credentials-ABdiWN",
    "Name": "db-credentials",
    "VersionId": "c97938b7-9891-4955-9b83-a30da86e778f"
}
harish@Harish:~/employeeBudget-Java-aws/rpsp_infra/iac/terraform$



SNS
-------------------------
aws sns create-topic \
  --name app-alerts \
  --region ap-south-1



Postgress setup in docker:
----------------------------------------

docker run -d --name local-postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=postgres \
  -p 5432:5432 \
  postgres:16

  docker exec -it local-postgres psql -U postgres
CREATE DATABASE employee_db;
CREATE DATABASE project_db;
CREATE DATABASE budget_db;
\q

cd infra
docker compose up -d