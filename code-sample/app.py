from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello():
    return "<center><h2>Flask inside Docker container in ECS cluster</h2></center>"


if __name__ == "__main__":
    app.run(debug=True,host='0.0.0.0', port=80)
