def handler(event, context):
    a,b,c = (event['a'], event['b'], event['c'])
    return {'delta': b - (4 * a* c), "a": a, "b": b}