from re import search
def handler(event, context):
    token = event.get('token')
    result = search(r'(.*)x\^2(.*)x(.*)', token)
    a = float(result.group(1)) if  result.group(1) != "" else 1
    b,c = (float(result.group(2)), float(result.group(3)))
    return {
        "a": a,
        "b": b,
        "c": c
    }
