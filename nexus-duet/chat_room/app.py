from flask import Flask, render_template, request, session, redirect, url_for
from flask_socketio import SocketIO, emit, join_room, leave_room
import datetime

app = Flask(__name__)
app.config['SECRET_KEY'] = 'your_super_secret_key_here' # Change this!
socketio = SocketIO(app)

# Store connected users and their SIDs
# Format: {sid: username}
connected_users = {}

@app.route('/')
def index():
    return render_template('index.html')

@socketio.on('connect')
def handle_connect():
    print(f'Client connected: {request.sid}')
    # No username yet, so we don't add to connected_users here

@socketio.on('disconnect')
def handle_disconnect():
    username = connected_users.pop(request.sid, 'An unknown user')
    if username != 'An unknown user':
        emit('user_left', {'username': username}, broadcast=True)
        print(f'User disconnected: {username} ({request.sid})')
    else:
        print(f'Client disconnected: {request.sid} (before setting username)')


@socketio.on('set_username')
def handle_set_username(data):
    username = data['username'].strip()

    if not username:
        emit('username_error', {'message': 'Username cannot be empty.'})
        return

    # Check if username is already taken by another connected user
    if username in connected_users.values():
        emit('username_error', {'message': 'Username is already taken.'})
        return

    # Store the username with the session ID
    connected_users[request.sid] = username
    print(f'User {username} set for SID: {request.sid}')

    # Notify the client that their username was successfully set
    emit('username_set_success', {'username': username})

    # Notify all other clients that a new user has joined
    emit('user_joined', {'username': username}, broadcast=True, include_self=False)

    # Send the current list of users to the newly joined client
    emit('current_users', {'users': list(connected_users.values())})

    # Send the current list of users to all clients
    emit('update_user_list', {'users': list(connected_users.values())}, broadcast=True)


@socketio.on('send_message')
def handle_send_message(data):
    message = data['message'].strip()
    username = connected_users.get(request.sid)

    if not username:
        emit('message_error', {'message': 'You need to set a username first!'})
        return

    if not message:
        return # Don't send empty messages

    timestamp = datetime.datetime.now().strftime('%H:%M')
    print(f'[{timestamp}] {username}: {message}')
    emit('new_message', {'username': username, 'message': message, 'timestamp': timestamp}, broadcast=True)


if __name__ == '__main__':
    socketio.run(app, debug=True) # allow_unsafe_werkzeug for development

