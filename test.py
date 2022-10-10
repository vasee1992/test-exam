from re import L
import boto3

def list_all_regions():
    ec2_client = boto3.client('ec2')
    response = ec2_client.describe_regions()
    return [x['RegionName'] for x in response['Regions']]

def list_resources_by_region(REGION):
    api = boto3.client('resourcegroupstaggingapi',region_name=REGION)
    def lookup_for_tags(token):
        try:
            response = api.get_resources(
                PaginationToken=token,
                ResourcesPerPage=50,)
            return response
        except Exception as e:
            print(f"Error when attempting to list resources: {e}")

    total_results = []
    response = lookup_for_tags("")
    page_token = ""

    while True:
        total_results += response["ResourceTagMappingList"]
        page_token = response["PaginationToken"]
        if page_token == "":
            break
        response = lookup_for_tags(page_token)

    if total_results != []:
        return [x['ResourceARN'] for x  in total_results]
    else:
        return f"No resources use in region {REGION}"

def list_ec2_detail(REGION):
    ec2 = boto3.resource('ec2', region_name=REGION)
    instances = ec2.instances.all()
    for instance in instances:
        print(f'EC2 instance {instance.id}" information:')
        print(f'Instance state: {instance.state["Name"]}')
        print(f'Instance AMI: {instance.image.id}')
        print(f'Instance platform: {instance.platform}')
        print(f'Instance type: "{instance.instance_type}')
        print(f'Piblic IPv4 address: {instance.public_ip_address}')
        print('-'*60)

def list_rds_detail(REGION):
    rds = boto3.client('rds', region_name=REGION)
    response = rds.describe_db_instances()
    for instance in response['DBInstances']:
        print(f"DB Name: {instance['DBName']}")
        print(f"DB Indentifier: {instance['DBInstanceIdentifier']}")
        print(f"DB Class: {instance['DBInstanceClass']}")
        print(f"DB Storage: {instance['AllocatedStorage']}")
        print(f"DB Engine: {instance['Engine']}")
        print('-'*60)

def answer_question_1():
    for region in list_all_regions():
        resources = list_resources_by_region(region)
        print(f"{region} - {resources}")

def answer_question_2():
    for region in list_all_regions():
        list_ec2_detail(region)

    for region in list_all_regions():
        list_rds_detail(region)

answer_question_1()
answer_question_2()