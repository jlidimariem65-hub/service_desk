from flask import Flask, render_template, request, redirect, flash, url_for, session
import mysql.connector
import uuid
from datetime import datetime

app = Flask(__name__)
app.secret_key = "secret123"

# =========================
# Connexion DB
# =========================
appdatabase = mysql.connector.connect(
    host="localhost",
    user="root",
    password="1234",
    database="bhbank"
)

# =========================
# HOME / LOGIN PAGE
# =========================
@app.route('/')
@app.route('/home')
def home():
    return render_template("login.html")  # ton formulaire login

# =========================
# LOGIN
# =========================
# LOGIN
@app.route('/login', methods=['POST'])
def login():
    email = request.form.get('email')
    password = request.form.get('password')

    if not email or not password:
        flash("❌ Veuillez remplir tous les champs")
        return redirect(url_for('home'))

    cursor = appdatabase.cursor(dictionary=True)
    cursor.execute("SELECT * FROM utilisateurs WHERE email=%s AND mot_de_passe_hash=%s", (email, password))
    user = cursor.fetchone()

    if user:
        session['user'] = user['email']
        session['role'] = user['role']
        if user['role'] == 'admin':
            return redirect(url_for('dashboard'))
        else:
            return redirect(url_for('index'))
    else:
        flash("❌ Compte non trouvé ou mot de passe incorrect")
        return redirect(url_for('home'))
# =========================
# DASHBOARD ADMIN
# =========================
@app.route('/dashboard')
def dashboard():
    if 'user' not in session:
        flash("❌ Vous devez être connecté")
        return redirect(url_for('home'))

    if session.get('role') != 'admin':
        flash("❌ Accès interdit")
        return redirect(url_for('index'))

    cursor = appdatabase.cursor(dictionary=True)
    cursor.execute("SELECT * FROM tickets ORDER BY date_creation DESC")
    tickets = cursor.fetchall()
    return render_template("dashboard.html", tickets=tickets, email=session['user'])

# =========================
# INDEX UTILISATEUR
# =========================
@app.route('/index')
def index():
    if 'user' not in session:
        flash("❌ Vous devez être connecté")
        return redirect(url_for('home'))

    cursor = appdatabase.cursor(dictionary=True)
    cursor.execute("""
        SELECT t.ticket_uuid, t.titre, t.description, t.priorite, s.nom AS statut, t.date_creation
        FROM tickets t
        LEFT JOIN statut_ticket s ON t.statut_id = s.id
        JOIN utilisateurs u ON t.demandeur_id = u.id
        WHERE u.email=%s
        ORDER BY t.date_creation DESC
    """, (session['user'],))
    tickets = cursor.fetchall()

    return render_template("index.html", email=session['user'], tickets=tickets)

# =========================
# AJOUTER UN TICKET
# =========================
@app.route('/add_ticket', methods=['POST'])
def add_ticket():
    if 'user' not in session:
        flash("❌ Vous devez être connecté")
        return redirect(url_for('home'))

    titre = request.form.get('objet')
    description = request.form.get('details')
    statut = request.form.get('statut')
    date_service = request.form.get('date_service')

    if not titre or not description or not statut:
        flash("❌ Tous les champs sont obligatoires")
        return redirect(url_for('index'))

    try:
        cursor = appdatabase.cursor(dictionary=True)

        # Récupérer l'ID de l'utilisateur connecté
        cursor.execute("SELECT id FROM utilisateurs WHERE email=%s", (session['user'],))
        user = cursor.fetchone()
        demandeur_id = user['id']

        # Récupérer l'ID du statut
        cursor.execute("SELECT id FROM statut_ticket WHERE nom=%s", (statut,))
        statut_row = cursor.fetchone()
        statut_id = statut_row['id'] if statut_row else 1

        ticket_uuid = str(uuid.uuid4())
        query = """
            INSERT INTO tickets (ticket_uuid, titre, description, priorite, demandeur_id, statut_id, date_creation)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """
        cursor.execute(query, (ticket_uuid, titre, description, "moyenne", demandeur_id, statut_id, datetime.now()))
        appdatabase.commit()

        flash("✅ Ticket créé avec succès")
        return redirect(url_for('index'))
    except Exception as e:
        print("❌ ERREUR:", e)
        flash("❌ Erreur lors de la création")
        return redirect(url_for('index'))

# =========================
# LOGOUT
# =========================
@app.route('/logout')
def logout():
    session.pop('user', None)
    flash("✅ Déconnecté avec succès")
    return redirect(url_for('home'))

# =========================
# RUN
# =========================
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
