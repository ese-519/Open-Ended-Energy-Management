import socket
import json
import boto3
import botocore
from boto3.dynamodb.conditions import Key, Attr
ec2_addr='158.130.160.166' # karuna's machine 
#ec2_addr = '54.165.125.83'
#ec2_addr = '158.130.166.151' # bob's machine
ec2_tcp_port = 9000
#message = 'This is the message.  It will be repeated.'
searchbin_usage = 'Null'
searchbin_building = 'Null'

def lambda_handler(event, context):
    if (event['session']['application']['applicationId'] !=
        "amzn1.ask.skill.2f62b83b-282b-4c46-a5a8-e2feb4055015"):
        raise ValueError("Invalid Application ID")
    
    if event["request"]["type"] == "LaunchRequest":
        return on_launch(event["request"], event["session"])
    elif event["request"]["type"] == "IntentRequest":
        return on_intent(event["request"], event["session"])
    elif event["request"]["type"] == "SessionEndedRequest":
        return on_session_ended(event["request"], event["session"])
    else:
        return on_session_ended(event["request"], event["session"])

def client_tcp_session(server_addr, server_port, message):
    # Create a TCP/IP socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    # Connect the socket to the port where the server is listening
    server_address = (server_addr, server_port)
    sock.connect(server_address)
    alldata = []
    end_flag = '$'

    try:
        # Send data
        sock.sendall(message + end_flag)
    except Exception as e:
        return "Exception during sendall"
    else:
        # Look for the response
        while True:
            data = sock.recv(16)
            alldata.append(data)
            if end_flag in data:
                break
    finally:
        sock.close()
    if len(alldata) > 0:
        alldata_str = ''.join(alldata)
        alldata_str = alldata_str[0:-1]
        return alldata_str
    else:
        return 'No response data received.'
        

def on_intent(intent_request, session):
    intent = intent_request["intent"]
    intent_name = intent_request["intent"]["name"]

    if intent_name == "AMAZON.HelpIntent":
        return get_welcome_response()
    elif intent_name == "AMAZON.CancelIntent" or intent_name == "AMAZON.StopIntent":
        return handle_session_end_request()
    elif intent_name == "DescribeConditionsForUsage":
        return describe_conditions_for_usage(intent)
    elif intent_name == "PredictDay":
        return predict_day(intent)
    elif intent_name == "PredictMonth":
        return predict_month(intent)
    elif intent_name == "EvalOneSetPointsChange":
        return eval_one_set_points_change(intent)
    elif intent_name == "EvalTwoSetPointsChange":
        return eval_two_set_points_change(intent)
    elif intent_name == "SuggestGoodStrategy":
        return suggest_good_strategy(intent)
    elif intent_name == "BestStrategy":
        return best_strategy(intent)
    elif intent_name == "DescribeConditionsOnlyBuilding":
        return describe_conditions_only_building(intent)
    elif intent_name == "DescribeConditionsOnlyUsage":
        return describe_conditions_only_usage(intent)
    elif intent_name == "EvalTwoSetPointsNoTime":
        return eval_two_set_points_no_time(intent)
    elif intent_name == "EvalAllSetPointsTime":
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table('prev_num_setp')
        try:
            response = table.get_item(
                Key={
                    'id' : 1
                }
            )
        except botocore.exceptions.ClientError as e:
            print(e.response['Error']['Message'])
        else:
            response = response['Item']
            num_setp = response['num_setp']
        if num_setp == 1:
            return eval_one_set_point_with_time(intent)
        else:
            return eval_all_set_points_time(intent)
    elif intent_name == "EvalOneSetPointsNoTime":
        return eval_one_set_point_no_time(intent)
    else:
        return invalid_intent()
#        raise ValueError("Invalid intent")

def on_launch(launch_request, session):
    return get_welcome_response()
    
def get_welcome_response():
    session_attributes = {}
    card_title = "Energy Advisor"
    speech_output = "Welcome to the Alexa Energy Advisor skill"
    reprompt_text = speech_output
    should_end_session = False
    return build_response(session_attributes, build_speechlet_response(
        card_title, speech_output, reprompt_text, should_end_session))

def build_speechlet_response(title, output, reprompt_text, should_end_session):
    return {
        "outputSpeech": {
            "type": "PlainText",
            "text": output
        },
        "card": {
            "type": "Simple",
            "title": title,
            "content": output
        },
        "reprompt": {
            "outputSpeech": {
                "type": "PlainText",
                "text": reprompt_text
            }
        },
        "shouldEndSession": should_end_session
    }

def build_response(session_attributes, speechlet_response):
    return {
        "version": "1.0",
        "sessionAttributes": session_attributes,
        "response": speechlet_response
    }
    
def handle_session_end_request():
    card_title = "Energy Advisor - Thanks"
    speech_output = "Thank you for using the Energy Advisor skill.  See you next time!"
    should_end_session = True
    return build_response({}, build_speechlet_response(card_title, speech_output, None, should_end_session))
    
def describe_conditions_for_usage(intent):
    session_attributes = {}
    card_title = "Energy Advisor Building Conditions"
    reprompt_text = "How can I help you"
    should_end_session = False
    
    building = intent["slots"]["Building"]["value"]
    usagekW = int(intent["slots"]["UsagekW"]["value"])

    # build query, send to ec2, get response
    query_params = {'type': 1, 'building': building, 'usagekW': usagekW} 
    query_str = json.dumps(query_params)
    query_res_str = client_tcp_session(ec2_addr, ec2_tcp_port, query_str)
    query_res = json.loads(query_res_str)

    # parse response from server and build speech_output
    if 'error_msg' in query_res.keys():
        speech_output = 'I am sorry, there was an error.' + query_res['error_msg']
    else:
        time_int = int(query_res['TimeOfDay'])
        if time_int <= 11:
          time_str = str(time_int) + ' AM'
        elif time_int == 12:
          time_str = str(time_int) + ' PM'
        else:
          time_str = str(time_int - 12) + ' PM'
        speech_output = 'The building {} used {} kilowatts on average around {}' \
          'when the temperature is {} degrees celsius and humidity is {} percent'.format(
          building, usagekW, time_str, query_res['AvgTemperature'], query_res['AvgHumidity'])

    return build_response(session_attributes, build_speechlet_response(
        card_title, speech_output, reprompt_text, should_end_session))

def describe_conditions_only_building(intent):
    session_attributes = {}
    card_title = "Energy Advisor Building Conditions Only Building Specified"
    reprompt_text = "How can I help you"
    should_end_session = False
    
    global searchbin_building, searchbin_usage
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('searchbin')

    searchbin_building = intent["slots"]["Building"]["value"]

    try:
        response = table.get_item(
            Key={
                'id' : '1'
            }
        )
    except botocore.exceptions.ClientError as e:
        print(e.response['Error']['Message'])
    else:
        response = response['Item']
        searchbin_usage = response['wattage']

    if searchbin_building != 'Null' and searchbin_usage != 'Null':
        # build query, send to ec2, get response
        query_params = {'type': 1, 'building': searchbin_building, 'usagekW' :
                int(searchbin_usage)}
        query_str = json.dumps(query_params)
        query_res_str = client_tcp_session(ec2_addr, ec2_tcp_port, query_str)
        query_res = json.loads(query_res_str)

        # parse response from server and build speech_output
        if 'error_msg' in query_res.keys():
            speech_output = 'I am sorry, there was an error.' + query_res['error_msg']
        else:
            time_int = int(query_res['TimeOfDay'])
            if time_int <= 11:
              time_str = str(time_int) + ' AM'
            elif time_int == 12:
              time_str = str(time_int) + ' PM'
            else:
              time_str = str(time_int - 12) + ' PM'

        speech_output = 'The building {} used {} kilowatts on average around {}' \
          'when the temperature is {} degrees celsius and humidity is {} percent'.format(
          searchbin_building, int(searchbin_usage), time_str, query_res['AvgTemperature'], query_res['AvgHumidity'])

        response = table.update_item(
            Key={
                'id': '1'
            },
            UpdateExpression="SET building = :r, wattage = :s",
            ExpressionAttributeValues={
                ':r': 'Null',
                ':s': 'Null'
            },
            ReturnValues="UPDATED_NEW"
        )

        return build_response(session_attributes, build_speechlet_response(
            card_title, speech_output, reprompt_text, should_end_session))

    else:
        response = table.update_item(
            Key={
                'id': '1'
            },
            UpdateExpression="SET building=:r",
            ExpressionAttributeValues={
                ':r': searchbin_building
            },
            ReturnValues="UPDATED_NEW"
        )
        speech_output = 'For {}, What is the wattage you are expecting'.format(
          searchbin_building)
        reprompt_text = speech_output
        
        return build_response(session_attributes, build_speechlet_response(
            card_title, speech_output, reprompt_text, should_end_session))
        

def describe_conditions_only_usage(intent):
    session_attributes = {}
    card_title = "Energy Advisor Building Conditions Only Usage Specified"
    reprompt_text = "How can I help you"
    should_end_session = False
    
    global searchbin_building, searchbin_usage
    searchbin_usage = intent["slots"]["UsagekW"]["value"]
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('searchbin')

    try:
        response = table.get_item(
            Key={
                'id' : '1'
            }
        )
    except ClientError as e:
        print(e.response['Error']['Message'])
    else:
        response = response['Item']
        searchbin_building = response['building']

    if searchbin_building != 'Null' and searchbin_usage != 'Null':
        # build query, send to ec2, get response
        query_params = {'type': 1, 'building': searchbin_building, 'usagekW' :
                int(searchbin_usage)}
        query_str = json.dumps(query_params)
        query_res_str = client_tcp_session(ec2_addr, ec2_tcp_port, query_str)
        query_res = json.loads(query_res_str)

        # parse response from server and build speech_output
        if 'error_msg' in query_res.keys():
            speech_output = 'I am sorry, there was an error.' + query_res['error_msg']
        else:
            time_int = int(query_res['TimeOfDay'])
            if time_int <= 11:
              time_str = str(time_int) + ' AM'
            elif time_int == 12:
              time_str = str(time_int) + ' PM'
            else:
              time_str = str(time_int - 12) + ' PM'

        speech_output = 'The building {} used {} kilowatts on average around {}' \
          'when the temperature is {} degrees celsius and humidity is {} percent'.format(
          searchbin_building, int(searchbin_usage), time_str, query_res['AvgTemperature'], query_res['AvgHumidity'])

        response = table.update_item(
            Key={
                'id': '1'
            },
            UpdateExpression="SET building = :r, wattage = :s",
            ExpressionAttributeValues={
                ':r': 'Null',
                ':s': 'Null'
            },
            ReturnValues="UPDATED_NEW"
        )
    else:
        response = table.update_item(
            Key={
                'id': '1',
            },
            UpdateExpression="SET wattage = :r",
            ExpressionAttributeValues={
                ':r': searchbin_usage
            },
            ReturnValues="UPDATED_NEW"
        )
        speech_output = 'Which building do you want to evaluate?'
        reprompt_text = speech_output
    
    return build_response(session_attributes, build_speechlet_response(
        card_title, speech_output, reprompt_text, should_end_session))

def predict_day(intent):
    session_attributes = {}
    card_title = "Energy Advisor Day Prediction"
    reprompt_text = "How can I help you"
    should_end_session = False
    
    day = intent["slots"]["Day"]["value"]
    query_params = {"type": 2, "day": day}
    query_str = json.dumps(query_params)
    query_res_str = client_tcp_session(ec2_addr, ec2_tcp_port, query_str)
    query_res = json.loads(query_res_str)

    # parse response from server and build speech_output
    speech_output = "On {}, the peak expected power is about {} megawatts".format(day, query_res['peak_kW'])
    return build_response(session_attributes, build_speechlet_response(
        card_title, speech_output, reprompt_text, should_end_session))

def predict_month(intent):
    session_attributes = {}
    card_title = "Energy Advisor Month Prediction"
    reprompt_text = "How can I help you"
    should_end_session = False
    
    month = intent["slots"]["Month"]["value"]
    query_params = {"type": 3, "month": month}
    query_str = json.dumps(query_params)
    query_res_str = client_tcp_session(ec2_addr, ec2_tcp_port, query_str)
    query_res = json.loads(query_res_str)

    # parse response from server and build speech_output
    speech_output = "In {}, the peak expected power is about {} megawatts".format(month, query_res['peak_kW'])
    return build_response(session_attributes, build_speechlet_response(
        card_title, speech_output, reprompt_text, should_end_session))

def eval_one_set_points_change(intent):
    session_attributes = {}
    card_title = "Energy Advisor Evaluate Set Point Change"
    reprompt_text = "How can I help you"
    should_end_session = False

    setpoint_type = intent["slots"]["SetPointTypeOne"]["value"]
    setpoint_val = intent["slots"]["SetPointValOne"]["value"]
    start_time = intent["slots"]["StartTime"]["value"]
    end_time = intent["slots"]["EndTime"]["value"]

    query_params = {"type": 4, "setpoint_type": setpoint_type,
      "setpoint_val": setpoint_val, "start_time": start_time, "end_time": end_time}
    query_str = json.dumps(query_params)
    query_res_str = client_tcp_session(ec2_addr, ec2_tcp_port, query_str)
    query_res = json.loads(query_res_str)

    # parse response from server and build speech_output
    speech_output = "{} percent less energy would be used".format(query_res['percentage'])
    return build_response(session_attributes, build_speechlet_response(
        card_title, speech_output, reprompt_text, should_end_session))

def eval_two_set_points_change(intent):
    session_attributes = {}
    card_title = "Energy Advisor Evaluate Set Points Change"
    reprompt_text = "How can I help you"
    should_end_session = False

    setpoint_type1 = intent["slots"]["SetPointTypeOne"]["value"]
    setpoint_val1 = intent["slots"]["SetPointValOne"]["value"]
    setpoint_type2 = intent["slots"]["SetPointTypeTwo"]["value"]
    setpoint_val2 = intent["slots"]["SetPointValTwo"]["value"]
    start_time = intent["slots"]["StartTime"]["value"]
    end_time = intent["slots"]["EndTime"]["value"]

    query_params = {"type": 6, "setpoint_type1": setpoint_type1,
      "setpoint_val1": setpoint_val1, "start_time": start_time, "end_time": end_time,
      "setpoint_type2": setpoint_type2, "setpoint_val2": setpoint_val2}
    query_str = json.dumps(query_params)
    query_res_str = client_tcp_session(ec2_addr, ec2_tcp_port, query_str)
    query_res = json.loads(query_res_str)

    # parse response from server and build speech_output
    speech_output = "{} percent less energy would be used".format(query_res['percentage'])
    return build_response(session_attributes, build_speechlet_response(
        card_title, speech_output, reprompt_text, should_end_session))

def eval_two_set_points_no_time(intent):
    session_attributes = {}
    card_title = "Energy Advisor Evaluate Set Points Change"
    reprompt_text = "How can I help you"
    should_end_session = False

    setpoint_type1 = intent["slots"]["SetPointTypeOne"]["value"]
    setpoint_val1 = intent["slots"]["SetPointValOne"]["value"]
    setpoint_type2 = intent["slots"]["SetPointTypeTwo"]["value"]
    setpoint_val2 = intent["slots"]["SetPointValTwo"]["value"]

    # write received data into dynamodb
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('evaluator_two_setpoints')
    response = table.update_item(
        Key={
            'id': '1'
        },
        UpdateExpression="SET setpoint_type1= :r, setpoint_val1= :s, setpoint_type2= :t, setpoint_val2= :u",
        ExpressionAttributeValues={
            ':r': setpoint_type1,
            ':s': setpoint_val1,
            ':t': setpoint_type2,
            ':u': setpoint_val2
        },
        ReturnValues="UPDATED_NEW"
    )

    # write num_setp into dynamodb
    table = dynamodb.Table('prev_num_setp')
    response = table.update_item(
        Key={
            'id': 1
        },
        UpdateExpression="SET num_setp= :r",
        ExpressionAttributeValues={
            ':r': 2
        },
        ReturnValues="UPDATED_NEW"
    )

    speech_output = "Between which start and end times would you like these changes evaluated"
    reprompt_text = speech_output
    return build_response(session_attributes, build_speechlet_response(
        card_title, speech_output, reprompt_text, should_end_session))

def eval_all_set_points_time(intent):
    session_attributes = {}
    card_title = "Energy Advisor Evaluate Set Points Change"
    reprompt_text = "How can I help you"
    should_end_session = False

    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('evaluator_two_setpoints')

    try:
        response = table.get_item(
            Key={
                'id' : '1'
            }
        )
    except ClientError as e:
        print(e.response['Error']['Message'])
    else:
        response = response['Item']
        setpoint_type1 = response['setpoint_type1']
        setpoint_val1 = int(response['setpoint_val1'])
        setpoint_type2 = response['setpoint_type2']
        setpoint_val2 = int(response['setpoint_val2'])

    start_time = intent["slots"]["StartTime"]["value"]
    end_time = intent["slots"]["EndTime"]["value"]

    query_params = {"type": 6, "setpoint_type1": setpoint_type1,
      "setpoint_val1": setpoint_val1, "start_time": start_time, "end_time": end_time,
      "setpoint_type2": setpoint_type2, "setpoint_val2": setpoint_val2}
    query_str = json.dumps(query_params)
    query_res_str = client_tcp_session(ec2_addr, ec2_tcp_port, query_str)
    query_res = json.loads(query_res_str)

    # clear out dynamodb table
    response = table.update_item(
        Key={
            'id': '1'
        },
        UpdateExpression="SET setpoint_type1= :r, setpoint_val1= :s, setpoint_type2= :t, setpoint_val2= :u",
        ExpressionAttributeValues={
            ':r': "Null", 
            ':s': "Null",
            ':t': "Null",
            ':u': "Null"
        },
        ReturnValues="UPDATED_NEW"
    )

    # clear out num_setp in dynamodb
    table = dynamodb.Table('prev_num_setp')
    response = table.update_item(
        Key={
            'id': 1
        },
        UpdateExpression="SET num_setp= :r",
        ExpressionAttributeValues={
            ':r': 0
        },
        ReturnValues="UPDATED_NEW"
    )

    # parse response from server and build speech_output
    speech_output = "{} percent less energy would be used".format(query_res['percentage'])
    return build_response(session_attributes, build_speechlet_response(
        card_title, speech_output, reprompt_text, should_end_session))

def eval_one_set_point_no_time(intent):
    session_attributes = {}
    card_title = "Energy Advisor Evaluate One Set Point Change"
    reprompt_text = "How can I help you"
    should_end_session = False

    setpoint_type = intent["slots"]["SetPointTypeOne"]["value"]
    setpoint_val = intent["slots"]["SetPointValOne"]["value"]

    # write received data into dynamodb
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('evaluator_one_setpoint')
    response = table.update_item(
        Key={
            'id': '1'
        },
        UpdateExpression="SET setpoint_type= :r, setpoint_val= :s",
        ExpressionAttributeValues={
            ':r': setpoint_type,
            ':s': setpoint_val
        },
        ReturnValues="UPDATED_NEW"
    )

    # write num_setp into dynamodb
    table = dynamodb.Table('prev_num_setp')
    response = table.update_item(
        Key={
            'id': 1
        },
        UpdateExpression="SET num_setp= :r",
        ExpressionAttributeValues={
            ':r': 1
        },
        ReturnValues="UPDATED_NEW"
    )

    speech_output = "Between which start and end times would you like these changes evaluated"
    reprompt_text = speech_output
    return build_response(session_attributes, build_speechlet_response(
        card_title, speech_output, reprompt_text, should_end_session))

def eval_one_set_point_with_time(intent):
    session_attributes = {}
    card_title = "Energy Advisor Evaluate One Set Point Change with Time"
    reprompt_text = "How can I help you"
    should_end_session = False

    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('evaluator_one_setpoint')

    try:
        response = table.get_item(
            Key={
                'id' : '1'
            }
        )
    except ClientError as e:
        print(e.response['Error']['Message'])
    else:
        response = response['Item']
        setpoint_type = response['setpoint_type']
        setpoint_val = int(response['setpoint_val'])

    start_time = intent["slots"]["StartTime"]["value"]
    end_time = intent["slots"]["EndTime"]["value"]

    query_params = {"type": 4, "setpoint_type": setpoint_type,
      "setpoint_val": setpoint_val, "start_time": start_time, "end_time": end_time}
    query_str = json.dumps(query_params)
    query_res_str = client_tcp_session(ec2_addr, ec2_tcp_port, query_str)
    query_res = json.loads(query_res_str)

    # clear out dynamodb table
    response = table.update_item(
        Key={
            'id': '1'
        },
        UpdateExpression="SET setpoint_type= :r, setpoint_val= :s",
        ExpressionAttributeValues={
            ':r': "Null", 
            ':s': "Null"
        },
        ReturnValues="UPDATED_NEW"
    )

    # clear out num_setp in dynamodb
    table = dynamodb.Table('prev_num_setp')
    response = table.update_item(
        Key={
            'id': 1
        },
        UpdateExpression="SET num_setp= :r",
        ExpressionAttributeValues={
            ':r': 0
        },
        ReturnValues="UPDATED_NEW"
    )

    # parse response from server and build speech_output
    speech_output = "{} percent less energy would be used".format(query_res['percentage'])
    return build_response(session_attributes, build_speechlet_response(
        card_title, speech_output, reprompt_text, should_end_session))

def suggest_good_strategy(intent):
    session_attributes = {}
    card_title = "Energy Advisor Suggest a good strategy"
    reprompt_text = "How can I help you"
    should_end_session = False

    query_params = {"type": 5}
    query_str = json.dumps(query_params)
    query_res_str = client_tcp_session(ec2_addr, ec2_tcp_port, query_str)
    query_res = json.loads(query_res_str)

    # parse response from server and build speech_output
    speech_output = "The most optimal strategy out of the suggested three strategies will use {} kWh of energy".format(query_res['peak_kW']) #TODO: complete
    return build_response(session_attributes, build_speechlet_response(
        card_title, speech_output, reprompt_text, should_end_session))

def best_strategy(intent):
    #TODO: implement
    pass

def invalid_intent():
    session_attributes = {}
    card_title = "Energy Advisor Evaluate Set Point Change"
    reprompt_text = "How can I help you"
    should_end_session = False
    speech_output = "I'm sorry, I don't recognize that request"
    return build_response(session_attributes, build_speechlet_response(
        card_title, speech_output, reprompt_text, should_end_session))
  
