"""
MyLearnTracker - Personal Learning Goal Tracker API
====================================================
A REST API to track courses you want to learn.

Built with:
- Flask: The web framework that handles HTTP requests
- JSON file: Simple text file for storing data (no database needed!)
"""

from flask import Flask, jsonify, request  # Flask tools we'll use
from flask_cors import CORS                 # Allows browser frontends to call this API
import json                                 # For reading/writing JSON files
import os                                   # For checking if files exist
from datetime import datetime               # For timestamping new courses

# ============================================================
# APP SETUP
# ============================================================

# Create our Flask application
# __name__ tells Flask where to look for templates/static files
app = Flask(__name__)
CORS(app)  # Enable CORS for all routes — allows browser dashboards to call this API

# The name of our data file — all courses will be saved here
DATA_FILE = 'courses.json'


# ============================================================
# HELPER FUNCTIONS
# ============================================================

def load_courses():
    """
    Read all courses from the JSON file.
    
    - If the file doesn't exist yet, we create an empty one.
    - If the file is corrupted, we return an empty list (safe fallback).
    
    Returns: list of course dicts
    """
    if not os.path.exists(DATA_FILE):
        # First run — create an empty JSON array file
        with open(DATA_FILE, 'w') as f:
            json.dump([], f)
        return []

    try:
        with open(DATA_FILE, 'r') as f:
            return json.load(f)
    except json.JSONDecodeError:
        # File exists but contains invalid JSON — return safe empty list
        return []


def save_courses(courses):
    """
    Write the courses list back to the JSON file.
    
    indent=2 makes the file human-readable (pretty printed).
    
    Returns: True if saved OK, False if something went wrong
    """
    try:
        with open(DATA_FILE, 'w') as f:
            json.dump(courses, f, indent=2)
        return True
    except Exception as e:
        print(f"❌ Error saving courses: {e}")
        return False


def get_next_id(courses):
    """
    Generate the next available integer ID.
    
    Example: if IDs are [1, 2, 3], returns 4.
    If no courses exist, starts at 1.
    """
    if not courses:
        return 1
    return max(course['id'] for course in courses) + 1


def find_course_by_id(courses, course_id):
    """
    Search for a course by its ID.
    
    Returns a tuple: (course_dict, index_in_list)
    If not found: returns (None, -1)
    
    Why return the index? So we can update/delete it directly.
    """
    for index, course in enumerate(courses):
        if course['id'] == course_id:
            return course, index
    return None, -1


def validate_course_data(data, required_fields):
    """
    Check that required fields are present, and that 'status' is valid.
    
    Args:
        data: dict from the request body
        required_fields: list of field names that must exist
    
    Returns: (is_valid: bool, error_message: str or None)
    """
    # Check for missing fields
    missing = [field for field in required_fields if field not in data]
    if missing:
        return False, f"Missing required fields: {', '.join(missing)}"

    # If status is being set/updated, validate the value
    valid_statuses = ['Not Started', 'In Progress', 'Completed']
    if 'status' in data and data['status'] not in valid_statuses:
        return False, f"Invalid status. Must be one of: {', '.join(valid_statuses)}"

    return True, None


# ============================================================
# HOME ROUTE — just to confirm the server is alive
# ============================================================

@app.route('/')
def home():
    """
    GET /
    Returns a welcome message and lists all available endpoints.
    This is useful when someone visits the API root.
    """
    return jsonify({
        'message': 'Welcome to MyLearnTracker API!',
        'version': '1.0',
        'endpoints': {
            'GET  /api/courses':         'Get all courses',
            'GET  /api/courses/<id>':    'Get one course by ID',
            'POST /api/courses':         'Add a new course',
            'PUT  /api/courses/<id>':    'Update a course',
            'DELETE /api/courses/<id>':  'Delete a course',
            'GET  /api/courses/stats':   'Get course statistics',
            'GET  /api/courses/search':  'Search courses by keyword',
        }
    })


# ============================================================
# CORE ENDPOINTS
# ============================================================

@app.route('/api/courses', methods=['GET'])
def get_all_courses():
    """
    GET /api/courses
    Returns every course in the JSON file.
    """
    try:
        courses = load_courses()
        return jsonify({
            'success': True,
            'count': len(courses),
            'courses': courses
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/courses/<int:course_id>', methods=['GET'])
def get_course(course_id):
    """
    GET /api/courses/<id>
    Returns one specific course by its integer ID.
    """
    try:
        courses = load_courses()
        course, _ = find_course_by_id(courses, course_id)
        if course:
            return jsonify({'success': True, 'course': course}), 200
        return jsonify({'success': False, 'error': f'Course with ID {course_id} not found'}), 404
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/courses', methods=['POST'])
def add_course():
    """
    POST /api/courses
    Creates a new course. Required: name, description, target_date, status
    """
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'error': 'No JSON data provided'}), 400

        is_valid, error_msg = validate_course_data(data, ['name', 'description', 'target_date', 'status'])
        if not is_valid:
            return jsonify({'success': False, 'error': error_msg}), 400

        courses = load_courses()
        new_course = {
            'id':          get_next_id(courses),
            'name':        data['name'],
            'description': data['description'],
            'target_date': data['target_date'],
            'status':      data['status'],
            'created_at':  datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }
        courses.append(new_course)

        if save_courses(courses):
            return jsonify({'success': True, 'message': 'Course added successfully', 'course': new_course}), 201
        return jsonify({'success': False, 'error': 'Failed to save course'}), 500
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/courses/<int:course_id>', methods=['PUT'])
def update_course(course_id):
    """
    PUT /api/courses/<id>
    Updates one or more fields on an existing course (partial update).
    """
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'error': 'No JSON data provided'}), 400

        courses = load_courses()
        course, index = find_course_by_id(courses, course_id)
        if not course:
            return jsonify({'success': False, 'error': f'Course with ID {course_id} not found'}), 404

        if 'status' in data:
            is_valid, error_msg = validate_course_data(data, [])
            if not is_valid:
                return jsonify({'success': False, 'error': error_msg}), 400

        for field in ['name', 'description', 'target_date', 'status']:
            if field in data:
                course[field] = data[field]
        courses[index] = course

        if save_courses(courses):
            return jsonify({'success': True, 'message': 'Course updated successfully', 'course': course}), 200
        return jsonify({'success': False, 'error': 'Failed to save changes'}), 500
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/courses/<int:course_id>', methods=['DELETE'])
def delete_course(course_id):
    """
    DELETE /api/courses/<id>
    Removes a course permanently.
    """
    try:
        courses = load_courses()
        course, index = find_course_by_id(courses, course_id)
        if not course:
            return jsonify({'success': False, 'error': f'Course with ID {course_id} not found'}), 404

        deleted = courses.pop(index)
        if save_courses(courses):
            return jsonify({'success': True, 'message': 'Course deleted successfully', 'deleted_course': deleted}), 200
        return jsonify({'success': False, 'error': 'Failed to save changes'}), 500
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


# ============================================================
# BONUS ENDPOINTS
# ============================================================

@app.route('/api/courses/stats', methods=['GET'])
def get_statistics():
    """
    GET /api/courses/stats
    Returns counts of courses grouped by status.
    """
    try:
        courses = load_courses()
        return jsonify({
            'success': True,
            'statistics': {
                'total_courses': len(courses),
                'not_started':   sum(1 for c in courses if c['status'] == 'Not Started'),
                'in_progress':   sum(1 for c in courses if c['status'] == 'In Progress'),
                'completed':     sum(1 for c in courses if c['status'] == 'Completed'),
            }
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/courses/search', methods=['GET'])
def search_courses():
    """
    GET /api/courses/search?q=keyword
    Searches course name AND description (case-insensitive).
    """
    try:
        query = request.args.get('q', '').strip().lower()
        if not query:
            return jsonify({'success': False, 'error': 'Search query "q" is required'}), 400

        courses = load_courses()
        results = [c for c in courses if query in c['name'].lower() or query in c['description'].lower()]
        return jsonify({'success': True, 'query': query, 'count': len(results), 'courses': results}), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


# ============================================================
# ERROR HANDLERS
# ============================================================

@app.errorhandler(404)
def not_found(error):
    return jsonify({'success': False, 'error': 'Endpoint not found'}), 404

@app.errorhandler(405)
def method_not_allowed(error):
    return jsonify({'success': False, 'error': 'Method not allowed'}), 405

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'success': False, 'error': 'Internal server error'}), 500


# ============================================================
# RUN
# ============================================================

if __name__ == '__main__':
    print("=" * 60)
    print("  MyLearnTracker API is starting...")
    print("=" * 60)
    print(f"  Data file: {os.path.abspath(DATA_FILE)}")
    print("  API URL:   http://localhost:5000")
    print("=" * 60)
    print("  Press CTRL+C to stop\n")
    app.run(debug=True, host='0.0.0.0', port=5000)
