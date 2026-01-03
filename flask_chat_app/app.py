from flask import Flask, render_template, request, session, redirect, url_for
from flask_socketio import SocketIO, emit, join_room, leave_room
import datetime

app = Flask(__name__)

@app.route('/captures/<path:filename>')
def custom_static(filename):
    import os
    from flask import send_from_directory
    return send_from_directory(os.path.join(app.root_path, '..'), filename)
app.config['SECRET_KEY'] = 'your_super_secret_key_here'
socketio = SocketIO(app)

connected_users = {}

@app.route('/')
def index():
    return render_template('index.html')

@socketio.on('connect')
def handle_connect():
    print(f'Client connected: {request.sid}')

@socketio.on('disconnect')
def handle_disconnect():
    username = connected_users.pop(request.sid, 'An unknown user')
    if username != 'An unknown user':
        emit('user_left', {'username': username}, broadcast=True)
    print(f'Client disconnected: {request.sid}')

@socketio.on('set_username')
def handle_set_username(data):
    username = data['username'].strip()
    if not username:
        emit('username_error', {'message': 'Username cannot be empty.'})
        return
    if username in connected_users.values():
        emit('username_error', {'message': 'Username is already taken.'})
        return
    connected_users[request.sid] = username
    emit('username_set_success', {'username': username})
    emit('user_joined', {'username': username}, broadcast=True, include_self=False)
    emit('update_user_list', {'users': list(connected_users.values())}, broadcast=True)

@socketio.on('send_message')
def handle_send_message(data):
    message = data['message'].strip()
    username = connected_users.get(request.sid)
    if not username:
        emit('message_error', {'message': 'You need to set a username first!'})
        return
    if message:
        timestamp = datetime.datetime.now().strftime('%H:%M')
        emit('new_message', {'username': username, 'message': message, 'timestamp': timestamp}, broadcast=True)

if __name__ == '__main__':
    # Listen on all interfaces so you can access it from your browser
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)
