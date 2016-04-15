
def application(env, start_response):
    status="200 OK"
    body = """Welcome to ACE!\n"""
    #f = open('default.html','r')
    f = open('index.html','r')
    content = f.read()
    f.close()
    response_headers = [("Content-type", "text/html")]
    start_response(status, response_headers)
    return [content]

if __name__ == "__main__":
    from wsgiref.simple_server import make_server
    httpd = make_server('localhost', 8080, application)
    httpd.serve_forever()



