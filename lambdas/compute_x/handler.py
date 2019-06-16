from math import sqrt
def handler_x1(event, context):
    a,b,delta = (event['a'], event['b'], event['delta'])
    x1 = (-1*b - sqrt(delta)) / 2*a
    return{"x1": x1}

    
def handler_x2(event, context):
    a,b,delta = (event['a'], event['b'], event['delta'])
    x2 = (-1*b + sqrt(delta)) / 2*a
    return{"x2": x2}