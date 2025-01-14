import time
import os
import sys
from sys import exit

userkey = sys.argv[2]
returnPath = "../BetterTemp/ai_return.txt"
requestPath = "../BetterTemp/ai_request.txt"
promptPath = "../BetterTemp/ai_prompt.txt"

noGp4 = True
swap3 = False

model = sys.argv[3]
if userkey == "":
    from freeGPT import Client

    nameAliases = {
        "gpt-3.5-turbo": ["gpt3_5", "gpt4", "gpt3"],
        "gpt-3.5-turbo-0125": ["gpt3_5", "gpt4", "gpt3"],
        "gpt-3.5-turbo-1106": ["gpt3_5", "gpt4", "gpt3"],
        "gpt-3.5-turbo-16k": ["gpt3_5", "gpt4", "gpt3"],
        "gpt-4o-mini": ["gpt4", "gpt3_5", "gpt3"],
        "gpt-4o-mini-2024-07-18": ["gpt4", "gpt3_5", "gpt3"],
        "": ["gpt4", "gpt3_5", "gpt3"]
    }

    if model in nameAliases:
        model = nameAliases[model]
    else:
        model = nameAliases[""]

    if swap3:
        if model == "gpt3_5":
            model = "gpt3"
        else:
            model = "gpt3_5"

    with open(requestPath) as requestFile:
        with open(promptPath) as promptFile:
            lasterr = "unknown error"
            for m in model:
                if m != "gpt4" or not noGp4:
                    try:
                        chat_response = Client.create_completion(m, promptFile.read() + "\n" + requestFile.read())

                        with open(returnPath, 'w') as f2:
                            f2.write(chat_response)
                            sys.exit(0)
                    except Exception as e:
                        lasterr = str(e)

            with open(returnPath, 'w') as f2:
                f2.write(lasterr)
else:
    os.environ["OPENAI_API_BASE"] = "https://api.openai.com/v1"
    import openai
    openai.api_key = userkey

    if model == "":
        model = "gpt-3.5-turbo"

    with open(requestPath) as requestFile:
        with open(promptPath) as promptFile:
            try:
                messages = [
                    {"role": "system", "content" : promptFile.read()},
                    {"role": "user", "content": requestFile.read()}
                ]

                completion = openai.ChatCompletion.create(
                    model = model,
                    messages = messages
                )

                chat_response = completion.choices[0].message.content

                with open(returnPath, 'w') as f2:
                    f2.write(chat_response)
            except Exception as e:
                with open(returnPath, 'w') as f2:
                    f2.write(str(e))
