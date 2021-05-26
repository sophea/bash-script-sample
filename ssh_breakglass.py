import boto3
import time
from cryptography.hazmat.primitives import serialization as crypto_serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.backends import default_backend as crypto_default_backend

def lambda_handler(event, context):

    # Initialise varialbles
    admin_ssh_user = 'ec2-user'
    auth_keys_path = '/home/' + admin_ssh_user + '/.ssh/authorized_keys'
    env = 'prod'
    
    # Generate an RSA key
    key = rsa.generate_private_key(
        backend=crypto_default_backend(),
        public_exponent=65537,
        key_size=2048
    )
    private_key = key.private_bytes(
        crypto_serialization.Encoding.PEM,
        crypto_serialization.PrivateFormat.PKCS8,
        crypto_serialization.NoEncryption())
    public_key = key.public_key().public_bytes(
        crypto_serialization.Encoding.OpenSSH,
        crypto_serialization.PublicFormat.OpenSSH
    )
    pub_key_txt = public_key.decode()
    pri_key_txt = private_key.decode()
    
    # Need to specify MaxResults as the default is 10
    secret_mgr_client = boto3.client('secretsmanager')
    secrets = secret_mgr_client.list_secrets(MaxResults=100)
    
    # Removing exiting key
    del_key_results=None
    print('Deleting a existing break-glass key')
    for key in secrets['SecretList']:
        if 'break-glass' in key['Name']:
            #print('del key:' + key['Name'])
            del_key_results=secret_mgr_client.delete_secret(SecretId=key['Name'], ForceDeleteWithoutRecovery=True)
    
    # Waiting 30 sec for key to delete
    if del_key_results != None:
        print('Waiting 30 seconds for deletion to complete')
        time.sleep(30)
    
    # Adding new break-glass private key in
    print('Adding a new break-glass key')
    add_secret_result = secret_mgr_client.create_secret(Name='prod-break-glass-private-key', SecretString=pri_key_txt)
    
    # Create a Security Token Service (STS) client
    sts_client = boto3.client('sts')
    
    # Assume a production breakglass_ssh role
    assumed_role_object=sts_client.assume_role(
        RoleArn="arn:aws:iam::391246823000:role/breakglass_ssh",
        RoleSessionName="AssumeRoleSession1"
    )
    credentials=assumed_role_object['Credentials']
    
    # Get a list of instances filtered by tag
    ec2_client = boto3.resource('ec2',
    aws_access_key_id=credentials['AccessKeyId'],
    aws_secret_access_key=credentials['SecretAccessKey'],
    aws_session_token=credentials['SessionToken'])
    instances = ec2_client.instances.filter(
        Filters=[{'Name': 'tag:' + 'patchgroup', 'Values': ['rhel']}])
    
    # Get a list of instance IDs
    ec2_list = []
    for instance in instances:
    #    print(instance.id, instance.instance_type)
        ec2_list.append(instance.id)
    
    # Update break-glass public key on instances
    print('Updating break-glass public key on servers')
    ssm_client = boto3.client('ssm',
    aws_access_key_id=credentials['AccessKeyId'],
    aws_secret_access_key=credentials['SecretAccessKey'],
    aws_session_token=credentials['SessionToken'])
    response = ssm_client.send_command(
                InstanceIds=ec2_list,
                DocumentName="AWS-RunShellScript",
                Parameters={'commands': ['sed -i \'/break_glass_' + env + '/d\' ' + auth_keys_path + ' &&' + 'echo ' + pub_key_txt + ' break_glass_' + env + ' >> ' + auth_keys_path]}, )

    return
    {
        'message' : "Breakglass script execution completed"
    }
