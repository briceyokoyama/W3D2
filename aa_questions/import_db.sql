PRAGMA foreign_keys = ON;



DROP TABLE question_follows;
DROP TABLE replies;
DROP TABLE question_likes;
DROP TABLE questions;
DROP TABLE users;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname TEXT NOT NULL,
  lname TEXT NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  user_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  parent_id INTEGER,
  body TEXT NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (parent_id) REFERENCES replies(id)
);

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO
  users (fname, lname)
VALUES
  ('Brice', 'Yokoyama'),
  ('Tim', 'Jao'),
  ('Mr', 'Guy')
  ;

INSERT INTO
  questions (title, body, user_id)
VALUES
  ('question1', '1?', (SELECT id FROM users WHERE fname = 'Brice' AND lname = 'Yokoyama')),
  ('question2', '2?', (SELECT id FROM users WHERE fname = 'Tim' AND lname = 'Jao')),
  ('question3', '3?', (SELECT id FROM users WHERE fname = 'Mr' AND lname = 'Guy')),
  ('question4', '4?', (SELECT id FROM users WHERE fname = 'Brice' AND lname = 'Yokoyama')),
  ('question5', '5?', (SELECT id FROM users WHERE fname = 'Brice' AND lname = 'Yokoyama'));

INSERT INTO
  question_follows (user_id, question_id)
VALUES
  ((SELECT id FROM users WHERE fname = 'Brice' AND lname = 'Yokoyama'), (SELECT id FROM questions WHERE title = 'question1' AND body = '1?')),
  ((SELECT id FROM users WHERE fname = 'Tim' AND lname = 'Jao'), (SELECT id FROM questions WHERE title = 'question1' AND body = '1?')),
  ((SELECT id FROM users WHERE fname = 'Tim' AND lname = 'Jao'), (SELECT id FROM questions WHERE title = 'question2' AND body = '2?')),
  ((SELECT id FROM users WHERE fname = 'Mr' AND lname = 'Guy'), (SELECT id FROM questions WHERE title = 'question1' AND body = '1?')),
  ((SELECT id FROM users WHERE fname = 'Mr' AND lname = 'Guy'), (SELECT id FROM questions WHERE title = 'question2' AND body = '2?')),
  ((SELECT id FROM users WHERE fname = 'Mr' AND lname = 'Guy'), (SELECT id FROM questions WHERE title = 'question3' AND body = '3?'));

INSERT INTO
  replies(user_id, question_id, parent_id, body)
VALUES
  ((SELECT id FROM users WHERE fname = 'Brice' AND lname = 'Yokoyama'), (SELECT id FROM questions WHERE title = 'question1' AND body = '1?'), NULL, '!');

INSERT INTO
  question_likes(user_id, question_id)
VALUES
  ((SELECT id FROM users WHERE fname = 'Brice' AND lname = 'Yokoyama'), (SELECT id FROM questions WHERE title = 'question1' AND body = '1?')),
  ((SELECT id FROM users WHERE fname = 'Tim' AND lname = 'Jao'), (SELECT id FROM questions WHERE title = 'question1' AND body = '1?')),
  ((SELECT id FROM users WHERE fname = 'Mr' AND lname = 'Guy'), (SELECT id FROM questions WHERE title = 'question1' AND body = '1?')),
  ((SELECT id FROM users WHERE fname = 'Brice' AND lname = 'Yokoyama'), (SELECT id FROM questions WHERE title = 'question2' AND body = '2?')),
  ((SELECT id FROM users WHERE fname = 'Brice' AND lname = 'Yokoyama'), (SELECT id FROM questions WHERE title = 'question3' AND body = '3?')),
  ((SELECT id FROM users WHERE fname = 'Brice' AND lname = 'Yokoyama'), (SELECT id FROM questions WHERE title = 'question4' AND body = '4?')),
  ((SELECT id FROM users WHERE fname = 'Brice' AND lname = 'Yokoyama'), (SELECT id FROM questions WHERE title = 'question4' AND body = '4?'));
