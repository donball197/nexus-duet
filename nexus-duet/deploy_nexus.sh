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
Flask
Flask-SQLAlchemy
Flask-WTF
python-dotenv

EOF_NEXUS
echo '  - Created: requirements.txt'

cat << 'EOF_NEXUS' > ".env"
# .env
SECRET_KEY='004212564177694f487e22645672526e64434268686d496e62615462614b676a6b576868516d4161'

EOF_NEXUS
echo '  - Created: .env'

cat << 'EOF_NEXUS' > "app.py"
import os
from datetime import timedelta
from functools import wraps

from flask import Flask, render_template, request, redirect, url_for, flash, session
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField
from wtforms.validators import DataRequired, EqualTo, Length, ValidationError
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

app = Flask(__name__)

# --- Configuration ---
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY')
if not app.config['SECRET_KEY']:
    # Fallback for development if .env is not loaded, but strongly discourage in production
    app.config['SECRET_KEY'] = 'a_fallback_secret_key_if_env_is_missing_and_only_for_dev'
    print("WARNING: SECRET_KEY not found in environment. Using a fallback key. "
          "Ensure .env is configured correctly for production.")

app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///site.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['PERMANENT_SESSION_LIFETIME'] = timedelta(minutes=30) # Session expires after 30 minutes

db = SQLAlchemy(app)

# --- Database Models ---
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)

    def set_password(self, password):
        """Hashes the password and stores it."""
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        """Checks if the provided password matches the stored hash."""
        return check_password_hash(self.password_hash, password)

    def __repr__(self):
        return f'<User {self.username}>'

# --- Forms ---
class RegistrationForm(FlaskForm):
    username = StringField('Username', validators=[
        DataRequired(message='Username is required.'),
        Length(min=2, max=20, message='Username must be between 2 and 20 characters.')
    ])
    password = PasswordField('Password', validators=[
        DataRequired(message='Password is required.'),
        Length(min=6, message='Password must be at least 6 characters long.')
    ])
    confirm_password = PasswordField('Confirm Password', validators=[
        DataRequired(message='Please confirm your password.'),
        EqualTo('password', message='Passwords must match.')
    ])
    submit = SubmitField('Register')

    def validate_username(self, username):
        """Custom validator to check if username already exists."""
        user = User.query.filter_by(username=username.data).first()
        if user:
            raise ValidationError('That username is taken. Please choose a different one.')

class LoginForm(FlaskForm):
    username = StringField('Username', validators=[DataRequired(message='Username is required.')])
    password = PasswordField('Password', validators=[DataRequired(message='Password is required.')])
    submit = SubmitField('Login')

# --- Helper Decorators ---
def login_required(f):
    """
    Decorator to protect routes that require user authentication.
    Redirects unauthenticated users to the login page.
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            flash('Please log in to access this page.', 'info')
            return redirect(url_for('login', next=request.url)) # Pass next URL for redirection after login
        return f(*args, **kwargs)
    return decorated_function

# --- Routes ---
@app.route('/')
def index():
    if 'user_id' in session:
        return redirect(url_for('dashboard'))
    return redirect(url_for('login'))

@app.route('/register', methods=['GET', 'POST'])
def register():
    if 'user_id' in session:
        return redirect(url_for('dashboard'))

    form = RegistrationForm()
    if form.validate_on_submit():
        new_user = User(username=form.username.data)
        new_user.set_password(form.password.data)
        db.session.add(new_user)
        db.session.commit()
        flash('Your account has been created! You can now log in.', 'success')
        return redirect(url_for('login'))
    return render_template('register.html', title='Register', form=form)

@app.route('/login', methods=['GET', 'POST'])
def login():
    if 'user_id' in session:
        return redirect(url_for('dashboard'))

    form = LoginForm()
    if form.validate_on_submit():
        user = User.query.filter_by(username=form.username.data).first()
        if user and user.check_password(form.password.data):
            session['user_id'] = user.id
            session['username'] = user.username # Store username for display
            session.permanent = True # Make session permanent based on PERMANENT_SESSION_LIFETIME
            flash(f'Welcome back, {user.username}!', 'success')
            next_page = request.args.get('next')
            return redirect(next_page or url_for('dashboard'))
        else:
            flash('Login Unsuccessful. Please check username and password', 'danger')
    return render_template('login.html', title='Login', form=form)

@app.route('/logout')
@login_required
def logout():
    session.pop('user_id', None)
    session.pop('username', None)
    flash('You have been logged out.', 'info')
    return redirect(url_for('login'))

@app.route('/dashboard')
@login_required # This route requires a user to be logged in
def dashboard():
    return render_template('dashboard.html', title='Dashboard', username=session.get('username'))

# --- Initial Database Setup ---
# This ensures tables are created when the application starts for the first time
# or if the database file is new/empty.
with app.app_context():
    db.create_all()

if __name__ == '__main__':
    app.run(debug=True) # Set debug=False in production!

EOF_NEXUS
echo '  - Created: app.py'

mkdir -p "templates"
cat << 'EOF_NEXUS' > "templates/base.html"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Secure Flask Login - {% block title %}{% endblock %}</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { padding-top: 56px; }
        .flash-message { margin-top: 15px; }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-dark fixed-top">
        <div class="container-fluid">
            <a class="navbar-brand" href="{{ url_for('index') }}">Flask Login</a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav me-auto mb-2 mb-lg-0">
                    <li class="nav-item">
                        <a class="nav-link" href="{{ url_for('dashboard') }}">Dashboard</a>
                    </li>
                </ul>
                <ul class="navbar-nav">
                    {% if 'user_id' in session %}
                        <li class="nav-item">
                            <span class="navbar-text me-3">
                                Welcome, {{ session.get('username') }}!
                            </span>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link btn btn-outline-light" href="{{ url_for('logout') }}">Logout</a>
                        </li>
                    {% else %}
                        <li class="nav-item">
                            <a class="nav-link btn btn-outline-light me-2" href="{{ url_for('login') }}">Login</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link btn btn-primary" href="{{ url_for('register') }}">Register</a>
                        </li>
                    {% endif %}
                </ul>
            </div>
        </div>
    </nav>

    <div class="container">
        {% with messages = get_flashed_messages(with_categories=true) %}
            {% if messages %}
                <div class="flash-message">
                    {% for category, message in messages %}
                        <div class="alert alert-{{ category }} alert-dismissible fade show" role="alert">
                            {{ message }}
                            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                        </div>
                    {% endfor %}
                </div>
            {% endif %}
        {% endwith %}

        {% block content %}{% endblock %}
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>

EOF_NEXUS
echo '  - Created: templates/base.html'

mkdir -p "templates"
cat << 'EOF_NEXUS' > "templates/register.html"
{% extends "base.html" %}
{% block title %}Register{% endblock %}
{% block content %}
<div class="row justify-content-center mt-5">
    <div class="col-md-6">
        <div class="card">
            <div class="card-header text-center">
                <h3>Register</h3>
            </div>
            <div class="card-body">
                <form method="POST">
                    {{ form.hidden_tag() }} <!-- CSRF Token -->
                    <div class="mb-3">
                        {{ form.username.label(class="form-label") }}
                        {{ form.username(class="form-control", placeholder="Enter username") }}
                        {% if form.username.errors %}
                            <div class="text-danger">
                                {% for error in form.username.errors %}
                                    <span>{{ error }}</span>
                                {% endfor %}
                            </div>
                        {% endif %}
                    </div>
                    <div class="mb-3">
                        {{ form.password.label(class="form-label") }}
                        {{ form.password(class="form-control", placeholder="Enter password") }}
                        {% if form.password.errors %}
                            <div class="text-danger">
                                {% for error in form.password.errors %}
                                    <span>{{ error }}</span>
                                {% endfor %}
                            </div>
                        {% endif %}
                    </div>
                    <div class="mb-3">
                        {{ form.confirm_password.label(class="form-label") }}
                        {{ form.confirm_password(class="form-control", placeholder="Confirm password") }}
                        {% if form.confirm_password.errors %}
                            <div class="text-danger">
                                {% for error in form.confirm_password.errors %}
                                    <span>{{ error }}</span>
                                {% endfor %}
                            </div>
                        {% endif %}
                    </div>
                    <div class="d-grid gap-2">
                        {{ form.submit(class="btn btn-primary") }}
                    </div>
                </form>
                <small class="text-muted d-block text-center mt-3">
                    Already have an account? <a href="{{ url_for('login') }}">Log In</a>
                </small>
            </div>
        </div>
    </div>
</div>
{% endblock %}

EOF_NEXUS
echo '  - Created: templates/register.html'

mkdir -p "templates"
cat << 'EOF_NEXUS' > "templates/login.html"
{% extends "base.html" %}
{% block title %}Login{% endblock %}
{% block content %}
<div class="row justify-content-center mt-5">
    <div class="col-md-6">
        <div class="card">
            <div class="card-header text-center">
                <h3>Login</h3>
            </div>
            <div class="card-body">
                <form method="POST">
                    {{ form.hidden_tag() }} <!-- CSRF Token -->
                    <div class="mb-3">
                        {{ form.username.label(class="form-label") }}
                        {{ form.username(class="form-control", placeholder="Enter username") }}
                        {% if form.username.errors %}
                            <div class="text-danger">
                                {% for error in form.username.errors %}
                                    <span>{{ error }}</span>
                                {% endfor %}
                            </div>
                        {% endif %}
                    </div>
                    <div class="mb-3">
                        {{ form.password.label(class="form-label") }}
                        {{ form.password(class="form-control", placeholder="Enter password") }}
                        {% if form.password.errors %}
                            <div class="text-danger">
                                {% for error in form.password.errors %}
                                    <span>{{ error }}</span>
                                {% endfor %}
                            </div>
                        {% endif %}
                    </div>
                    <div class="d-grid gap-2">
                        {{ form.submit(class="btn btn-primary") }}
                    </div>
                </form>
                <small class="text-muted d-block text-center mt-3">
                    Need an account? <a href="{{ url_for('register') }}">Sign Up</a>
                </small>
            </div>
        </div>
    </div>
</div>
{% endblock %}

EOF_NEXUS
echo '  - Created: templates/login.html'

mkdir -p "templates"
cat << 'EOF_NEXUS' > "templates/dashboard.html"
{% extends "base.html" %}
{% block title %}Dashboard{% endblock %}
{% block content %}
<div class="jumbotron text-center mt-5">
    <h1 class="display-4">Welcome to your Dashboard, {{ username }}!</h1>
    <p class="lead">This is a protected page, only accessible to logged-in users.</p>
    <hr class="my-4">
    <p>You can add more user-specific content and features here.</p>
    <a class="btn btn-primary btn-lg" href="{{ url_for('logout') }}" role="button">Logout</a>
</div>
{% endblock %}

EOF_NEXUS
echo '  - Created: templates/dashboard.html'

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