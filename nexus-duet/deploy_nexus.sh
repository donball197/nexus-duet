#!/bin/bash
set -e

echo '🚀 NEXUS GOD MODE: Initializing Deployment...'
echo '--------------------------------------------'

# 1. Ask User for Project Name
read -p 'Enter name for this project (folder name): ' PROJ_NAME
if [ -z "$PROJ_NAME" ]; then
  PROJ_NAME="nexus_project"
fi

echo "📂 Creating project directory: $PROJ_NAME"
mkdir -p "$PROJ_NAME"
cd "$PROJ_NAME"

echo '📝 Writing files...'
cat << 'EOF_NEXUS' > "requirements.txt"
Flask==2.3.3
Flask-SocketIO==5.3.0
simple-websocket==1.0.0

EOF_NEXUS
echo '  - Created: requirements.txt'

cat << 'EOF_NEXUS' > "app.py"
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
    socketio.run(app, debug=True, allow_unsafe_werkzeug=True) # allow_unsafe_werkzeug for development

EOF_NEXUS
echo '  - Created: app.py'

mkdir -p "templates"
cat << 'EOF_NEXUS' > "templates/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Flask-SocketIO Chat</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='style.css') }}">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/socket.io/4.0.1/socket.io.js"></script>
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js"></script>
</head>
<body>
    <div class="container">
        <div class="chat-header">
            <h1>Real-time Chat</h1>
        </div>

        <!-- Username Selection Area -->
        <div id="username-section" class="username-section">
            <input type="text" id="username-input" placeholder="Choose a username..." maxlength="15">
            <button id="set-username-btn">Enter Chat</button>
            <p id="username-error" class="error-message"></p>
        </div>

        <!-- Chat Application Area -->
        <div id="chat-app" class="chat-app hidden">
            <div class="sidebar">
                <h2>Users</h2>
                <ul id="user-list">
                    <!-- Users will be listed here by JavaScript -->
                </ul>
            </div>
            <div class="main-chat">
                <div id="messages" class="messages">
                    <!-- Chat messages will appear here -->
                </div>
                <div class="message-input-area">
                    <input type="text" id="message-input" placeholder="Type a message...">
                    <button id="send-button">Send</button>
                </div>
            </div>
        </div>
    </div>

    <script src="{{ url_for('static', filename='script.js') }}"></script>
</body>
</html>

EOF_NEXUS
echo '  - Created: templates/index.html'

mkdir -p "static"
cat << 'EOF_NEXUS' > "static/style.css"
/* General Styling */
body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    background-color: #1a1a2e; /* Dark background */
    color: #e0e0e0; /* Light text color */
    margin: 0;
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 100vh;
    padding: 20px;
    box-sizing: border-box;
}

.container {
    background-color: #2a2a4a; /* Slightly lighter dark for container */
    border-radius: 12px;
    box-shadow: 0 8px 30px rgba(0, 0, 0, 0.5);
    width: 100%;
    max-width: 900px;
    display: flex;
    flex-direction: column;
    overflow: hidden;
}

.chat-header {
    background-color: #3a3a5e; /* Header background */
    padding: 15px 25px;
    border-bottom: 1px solid #4a4a7a;
    text-align: center;
}

.chat-header h1 {
    margin: 0;
    font-size: 1.8em;
    color: #90caf9; /* A nice light blue accent */
}

/* Username Section */
.username-section {
    padding: 30px;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 15px;
}

.username-section input[type="text"] {
    width: 80%;
    max-width: 300px;
    padding: 12px 15px;
    border: 1px solid #4a4a7a;
    border-radius: 8px;
    background-color: #3a3a5e;
    color: #e0e0e0;
    font-size: 1em;
    outline: none;
    transition: border-color 0.3s ease;
}

.username-section input[type="text"]::placeholder {
    color: #a0a0c0;
}

.username-section input[type="text"]:focus {
    border-color: #90caf9;
}

/* Buttons */
button {
    background-color: #90caf9; /* Accent blue */
    color: #1a1a2e;
    border: none;
    padding: 12px 25px;
    border-radius: 8px;
    cursor: pointer;
    font-size: 1em;
    font-weight: bold;
    transition: background-color 0.3s ease, transform 0.2s ease;
    outline: none;
}

button:hover {
    background-color: #64b5f6; /* Lighter blue on hover */
    transform: translateY(-2px);
}

button:active {
    transform: translateY(0);
}

/* Error Message */
.error-message {
    color: #ff8a80; /* Light red for errors */
    font-size: 0.9em;
    margin-top: 5px;
    text-align: center;
}

/* Chat Application Layout */
.chat-app {
    display: flex;
    height: 600px; /* Fixed height for chat area */
}

.sidebar {
    width: 200px;
    background-color: #3a3a5e;
    padding: 20px;
    border-right: 1px solid #4a4a7a;
    display: flex;
    flex-direction: column;
}

.sidebar h2 {
    margin-top: 0;
    color: #90caf9;
    font-size: 1.4em;
    border-bottom: 1px solid #4a4a7a;
    padding-bottom: 10px;
    margin-bottom: 15px;
}

#user-list {
    list-style: none;
    padding: 0;
    margin: 0;
    overflow-y: auto; /* Scroll for many users */
    flex-grow: 1;
}

#user-list li {
    padding: 8px 0;
    color: #c0c0d0;
    font-size: 0.95em;
    display: flex;
    align-items: center;
}

#user-list li::before {
    content: '•';
    color: #4CAF50; /* Green dot for online */
    margin-right: 8px;
    font-size: 1.2em;
}

.main-chat {
    flex-grow: 1;
    display: flex;
    flex-direction: column;
}

.messages {
    flex-grow: 1;
    padding: 20px;
    overflow-y: auto; /* Scroll for messages */
    display: flex;
    flex-direction: column;
    gap: 10px;
}

.message {
    background-color: #3a3a5e;
    padding: 10px 15px;
    border-radius: 10px;
    max-width: 80%;
    align-self: flex-start; /* Default alignment */
    word-wrap: break-word; /* Ensure long words break */
    box-shadow: 0 2px 5px rgba(0, 0, 0, 0.2);
}

.message.system {
    background-color: #4a4a7a;
    color: #a0a0c0;
    font-style: italic;
    text-align: center;
    max-width: 100%;
}

.message .username {
    font-weight: bold;
    color: #90caf9;
    margin-right: 8px;
}

.message .timestamp {
    font-size: 0.8em;
    color: #8080a0;
    margin-left: 10px;
}

/* Message Input Area */
.message-input-area {
    display: flex;
    padding: 15px 20px;
    border-top: 1px solid #4a4a7a;
    background-color: #2a2a4a;
    gap: 10px;
}

.message-input-area input[type="text"] {
    flex-grow: 1;
    padding: 12px 15px;
    border: 1px solid #4a4a7a;
    border-radius: 8px;
    background-color: #3a3a5e;
    color: #e0e0e0;
    font-size: 1em;
    outline: none;
    transition: border-color 0.3s ease;
}

.message-input-area input[type="text"]::placeholder {
    color: #a0a0c0;
}

.message-input-area input[type="text"]:focus {
    border-color: #90caf9;
}

.message-input-area button {
    padding: 12px 20px;
    min-width: 80px;
}

/* Utility Classes */
.hidden {
    display: none !important;
}

/* Scrollbar Styling (Webkit only) */
.messages::-webkit-scrollbar,
#user-list::-webkit-scrollbar {
    width: 8px;
}

.messages::-webkit-scrollbar-track,
#user-list::-webkit-scrollbar-track {
    background: #2a2a4a;
}

.messages::-webkit-scrollbar-thumb,
#user-list::-webkit-scrollbar-thumb {
    background-color: #4a4a7a;
    border-radius: 10px;
    border: 2px solid #2a2a4a;
}

.messages::-webkit-scrollbar-thumb:hover,
#user-list::-webkit-scrollbar-thumb:hover {
    background-color: #5a5a8a;
}

/* Responsive Adjustments */
@media (max-width: 768px) {
    .chat-app {
        flex-direction: column;
        height: auto;
    }
    .sidebar {
        width: 100%;
        border-right: none;
        border-bottom: 1px solid #4a4a7a;
        height: 150px; /* Make sidebar shorter on mobile */
    }
    .main-chat {
        height: 400px; /* Adjust chat height */
    }
    .username-section input[type="text"],
    .username-section button {
        width: 90%;
    }
}

@media (max-width: 480px) {
    .chat-header h1 {
        font-size: 1.5em;
    }
    .message-input-area {
        flex-direction: column;
        gap: 8px;
    }
    .message-input-area button {
        width: 100%;
    }
}

EOF_NEXUS
echo '  - Created: static/style.css'

mkdir -p "static"
cat << 'EOF_NEXUS' > "static/script.js"
$(document).ready(function() {
    const socket = io(); // Connect to the SocketIO server

    const usernameInput = $('#username-input');
    const setUsernameBtn = $('#set-username-btn');
    const usernameError = $('#username-error');
    const usernameSection = $('#username-section');
    const chatApp = $('#chat-app');
    const messageInput = $('#message-input');
    const sendButton = $('#send-button');
    const messagesDiv = $('#messages');
    const userList = $('#user-list');

    let currentUsername = '';

    // --- Utility Functions ---
    function scrollToBottom() {
        messagesDiv.scrollTop(messagesDiv[0].scrollHeight);
    }

    function appendMessage(username, message, timestamp, isSystem = false) {
        const messageClass = isSystem ? 'system' : '';
        const messageElement = $(`<div class="message ${messageClass}"></div>`);
        if (isSystem) {
            messageElement.text(message);
        } else {
            messageElement.html(`<span class="username">${username}</span>: ${message}<span class="timestamp">${timestamp}</span>`);
        }
        messagesDiv.append(messageElement);
        scrollToBottom();
    }

    function updateUsers(users) {
        userList.empty();
        users.forEach(user => {
            userList.append($('<li>').text(user));
        });
    }

    // --- SocketIO Event Handlers ---

    // Connection events
    socket.on('connect', function() {
        console.log('Connected to server!');
    });

    socket.on('disconnect', function() {
        console.log('Disconnected from server!');
        // Optionally, show a message to the user
        appendMessage('System', 'You have been disconnected from the chat.', '', true);
        chatApp.addClass('hidden');
        usernameSection.removeClass('hidden');
        currentUsername = '';
    });

    // Username events
    setUsernameBtn.on('click', function() {
        const username = usernameInput.val().trim();
        if (username) {
            socket.emit('set_username', { 'username': username });
            usernameError.text(''); // Clear previous error
        } else {
            usernameError.text('Please enter a username.');
        }
    });

    // Allow pressing Enter in username input
    usernameInput.on('keypress', function(e) {
        if (e.which === 13) { // Enter key
            setUsernameBtn.click();
        }
    });

    socket.on('username_set_success', function(data) {
        currentUsername = data.username;
        usernameSection.addClass('hidden');
        chatApp.removeClass('hidden');
        messagesDiv.empty(); // Clear any previous messages if re-joining
        appendMessage('System', `Welcome, ${currentUsername}!`, '', true);
        messageInput.focus(); // Focus on message input
    });

    socket.on('username_error', function(data) {
        usernameError.text(data.message);
    });

    socket.on('user_joined', function(data) {
        appendMessage('System', `${data.username} has joined the chat.`, '', true);
    });

    socket.on('user_left', function(data) {
        appendMessage('System', `${data.username} has left the chat.`, '', true);
    });

    socket.on('current_users', function(data) {
        updateUsers(data.users);
    });

    socket.on('update_user_list', function(data) {
        updateUsers(data.users);
    });


    // Message events
    sendButton.on('click', function() {
        const message = messageInput.val().trim();
        if (message) {
            socket.emit('send_message', { 'message': message });
            messageInput.val(''); // Clear input
        }
    });

    // Allow pressing Enter in message input
    messageInput.on('keypress', function(e) {
        if (e.which === 13) { // Enter key
            sendButton.click();
        }
    });

    socket.on('new_message', function(data) {
        appendMessage(data.username, data.message, data.timestamp);
    });

    socket.on('message_error', function(data) {
        // This error should ideally not happen if UI enforces username first
        // But good to handle for robustness
        appendMessage('System', `Error: ${data.message}`, '', true);
    });
});

EOF_NEXUS
echo '  - Created: static/script.js'

echo '--------------------------------------------'
echo '⚙️  Setting up Environment...'

# Check if requirements.txt exists
if [ -f requirements.txt ]; then
    if [ ! -d 'venv' ]; then
        echo '  - Creating Python Virtual Environment (venv)...'
        python3 -m venv venv
    fi
    echo '  - Installing dependencies...'
    ./venv/bin/pip install --upgrade pip
    ./venv/bin/pip install -r requirements.txt
else
    echo '⚠️  No requirements.txt found. Skipping dependency install.'
fi

echo '--------------------------------------------'
echo '✅ Deployment Complete!'
echo 'To run your project:'
echo "  cd $PROJ_NAME"
echo '  source venv/bin/activate'
echo '  python app.py (or your main script)'
echo '--------------------------------------------'

# Optional: Ask to run immediately
read -p 'Do you want to attempt to run the project now? (y/n): ' RUN_NOW
if [[ "$RUN_NOW" =~ ^[Yy]$ ]]; then
    if [ -f app.py ]; then
        ./venv/bin/python app.py
    elif [ -f main.py ]; then
        ./venv/bin/python main.py
    else
        echo '❌ Could not find app.py or main.py to run automatically.'
    fi
fi