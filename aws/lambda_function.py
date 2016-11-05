# event format
# {
#   "session": {
#     "sessionId": "SessionId.5b9134fc-39c4-4c4f-b1ce-86fd54d2776b",
#     "application": {
#       "applicationId": "amzn1.ask.skill.2f62b83b-282b-4c46-a5a8-e2feb4055015"
#     },
#     "attributes": {},
#     "user": {
#       "userId": "amzn1.ask.account.AHKFXC4K4APST47XY6F5T6TLG2IA6WQKCG2THWGQNXLTLZBE3VVOCRLJUWGINGOOM6ABVPGYM6TSSG5EZLG6OM4IPOUU2W4YJABY2ZXYGXDVQLNP5HMOSE3SVCC4MJUPLMG2N234R3QXOYN6HBOWKZJVGVNRMOM6Z2QUYREUL6KWKOVA4JKBFRTT6Y3IF2PHKWKBMIKVIIPH6NY"
#     },
#     "new": true
#   },
#   "request": {
#     "type": "IntentRequest",
#     "requestId": "EdwRequestId.51e8d6be-9470-4f72-9444-17fad6859d1b",
#     "locale": "en-US",
#     "timestamp": "2016-10-03T02:43:28Z",
#     "intent": {
#       "name": "GetTopConsuming",
#       "slots": {}
#     }
#   },
#   "version": "1.0"
# }
import socket
import json

ec2_addr = '54.165.125.83'
ec2_tcp_port = 9000
#message = 'This is the message.  It will be repeated.'

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

def client_tcp_session(server_addr, server_port, message):
    # Create a TCP/IP socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    # Connect the socket to the port where the server is listening
    server_address = (server_addr, server_port)
    sock.connect(server_address)
    alldata = []

    try:
        # Send data
        sock.sendall(message)

        # Look for the response
        end_flag = '$'

        while True:
            data = sock.recv(16)
            if data[-1] == end_flag:
              break
            alldata.append(data)

    finally:
        sock.close()
    if len(alldata) > 0:
        return ''.join(alldata)
    else:
        return 'No response data received.'
        

def on_intent(intent_request, session):
    intent = intent_request["intent"]
    intent_name = intent_request["intent"]["name"]

    if intent_name == "AMAZON.HelpIntent":
        return get_welcome_response()
    elif intent_name == "AMAZON.CancelIntent" or intent_name == "AMAZON.StopIntent":
        return handle_session_end_request()
    elif intent_name == "GetBuildingStatus":
        return get_building_status(intent)
    elif intent_name == "GetTopConsuming":
        return get_top_consuming()
    elif intent_name == "GetPeakTime":
        return get_peak_time(intent)
    elif intent_name == "DescribeConditionsForUsage":
        return describe_conditions_for_usage(intent)
    else:
        raise ValueError("Invalid intent")

def on_launch(launch_request, session):
    return get_welcome_response()
    
def get_welcome_response():
    session_attributes = {}
    card_title = "Energy Advisor"
    speech_output = "Welcome to the Alexa Energy Advisor skill. " \
                    "You can ask me for information about energy usage of a " \
                    "building on Penn's campus, for the peak time for a building, " \
                    "or for the top consuming buildings on campus."
    reprompt_text = "Please ask me for the status of a building, " \
                    "for example College Hall."
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
    
def get_top_consuming():
    session_attributes = {}
    card_title = "Energy Advisor Top Consuming"
    reprompt_text = ""
    should_end_session = False

    speech_output = 'The top consuming buildings are currently College Hall and David Rittenhouse Laboratory'

    return build_response(session_attributes, build_speechlet_response(
        card_title, speech_output, reprompt_text, should_end_session))
        
def get_building_status(intent):
    session_attributes = {}
    card_title = "Energy Advisor Building Status"
    reprompt_text = ""
    should_end_session = False
    
    building = intent["slots"]["Building"]["value"]

    speech_output = 'The current energy usage for {0} is 10 kilowatt hours'.format(building)

    return build_response(session_attributes, build_speechlet_response(
        card_title, speech_output, reprompt_text, should_end_session))
        
def get_peak_time(intent):
    session_attributes = {}
    card_title = "Energy Advisor Peak Time"
    reprompt_text = ""
    should_end_session = False
    
    building = intent["slots"]["Building"]["value"]

    speech_output = 'Peak energy usage for {0} occurred at 3:15pm'.format(building)

    return build_response(session_attributes, build_speechlet_response(
        card_title, speech_output, reprompt_text, should_end_session))

def describe_conditions_for_usage(intent):
    session_attributes = {}
    card_title = "Energy Advisor Building Conditions"
    reprompt_text = ""
    should_end_session = False
    
    building = intent["slots"]["Building"]["value"]
    usagekW = intent["slots"]["UsagekW"]["value"]

    #TODO: build query, send to ec2, get response
    query_params = {'type': 1, 'building': 'Levine Hall', 'usagekW': 60} 
    query_str = json.dumps(query_params)
    speech_output = client_tcp_session(ec2_addr, ec2_tcp_port, query_str)

#    speech_output = '{} used {} killowats when add conditions here'.format(building, usagekW)

    return build_response(session_attributes, build_speechlet_response(
        card_title, speech_output, reprompt_text, should_end_session))

