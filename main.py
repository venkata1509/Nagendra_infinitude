from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy import Column, Integer, String, create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from pydantic import BaseModel

# Database setup
SQLALCHEMY_DATABASE_URL = "sqlite:///./courses.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Model
class Course(Base):
    __tablename__ = "courses"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(String)

# Create the database
Base.metadata.create_all(bind=engine)

# Pydantic schema
class CourseCreate(BaseModel):
    title: str
    description: str

# FastAPI app
app = FastAPI()

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# POST request to add a course
@app.post("/courses/")
def create_course(course: CourseCreate, db: Session = Depends(get_db)):
    db_course = Course(title=course.title, description=course.description)
    db.add(db_course)
    db.commit()
    db.refresh(db_course)
    return db_course

# GET request to retrieve courses
@app.get("/courses/")
def get_courses(db: Session = Depends(get_db)):
    courses = db.query(Course).all()
    return courses
