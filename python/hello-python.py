def lambda_handler(event, context):
    message= 'Shaunak-shunyeka {} !'.format(event['key1'])
    return{
        'message' :message
    }