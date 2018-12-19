from app import db
from sqlalchemy.dialects.postgresql import JSON


class Transaction(db.Model):
    __tablename__ = 'transaction'

    id = db.Column(db.String(), primary_key=True)
    size = db.Column(db.String())
    time = db.Column(db.String())
    valueout = db.Column(db.String())