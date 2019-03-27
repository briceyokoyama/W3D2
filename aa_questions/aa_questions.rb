require 'sqlite3'
require 'singleton'
require 'byebug'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

# ------------------------------------------------
# ------------------------------------------------
# ------------------------------------------------

class Users

  attr_accessor :id, :fname, :lname

  def self.find_by_id(id)
    data = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT *
      FROM users
      WHERE id = ?
    SQL
    Users.new(data.first)
  end

  def self.find_by_name(fname, lname)
    data = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT *
      FROM users
      WHERE fname = ? AND lname = ?
    SQL
    Users.new(data.first)
  end

  def initialize(data)
    @id = data['user_id'] || data['id']
    @fname = data['fname']
    @lname = data['lname']
  end

  def authored_questions
    Questions.find_by_author_id(self.id)
  end

  def authored_replies
    Replies.find_by_user_id(self.id)
  end

  def followed_questions
    Question_follows.followed_questions_for_user_id(self.id)
  end

  def liked_questions
    Question_likes.liked_questions_for_user_id(self.id)
  end

  def average_karma
    data = QuestionsDatabase.instance.execute(<<-SQL, self.id)
      SELECT CAST(COUNT(question_likes.user_id) AS FLOAT)/COUNT(DISTINCT(questions.id)) AS avg_num
      FROM questions
      LEFT OUTER JOIN question_likes ON questions.id = question_likes.question_id
      WHERE questions.user_id = ?
    SQL
    data.first['avg_num']
  end

  def create
    raise "#{self} already in database" if @id
    QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname)
      INSERT INTO
        users (fname, lname)
      VALUES
        (?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname, @id)
      UPDATE
        users 
      SET
        fname = ?, lname = ?
      WHERE
        id = ?
    SQL
  end

  def save
    if @id
      self.update
    else
      self.create
    end
  end

end

# ------------------------------------------------
# ------------------------------------------------
# ------------------------------------------------

class Questions

  attr_accessor :id, :title, :body, :user_id

  def self.find_by_id(id)
    data = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT *
      FROM questions
      WHERE id = ?
    SQL
    Questions.new(data.first)
  end

  def self.find_by_author_id(id)
    data = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT *
      FROM questions
      WHERE user_id = ?
    SQL
    data.map {|datum| Questions.new(datum)}
  end

  def initialize(data)
    @id = data['id']
    @title = data['title']
    @body = data['body']
    @user_id = data['user_id']
  end

  def author
    Users.find_by_id(self.user_id)
  end

  def replies
    Replies.find_by_question_id(self.id)
  end

  def followers
    Question_follows.followers_for_question_id(self.id)
  end

  def self.most_followed(n)
    Question_follows.most_followed_questions(n)
  end

  def likers
    Question_likes.likers_for_question_id(self.id)
  end

  def num_likes
    Question_likes.num_likes_for_question_id(self.id)
  end

  def most_liked(n)
    Question_likes.most_liked_questions(n)
  end

  def create
    raise "#{self} already in database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @user_id)
      INSERT INTO
        questions (title, body, user_id)
      VALUES
        (?, ?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @user_id, @id)
      UPDATE
        questions 
      SET
        title = ?, body = ?, user_id = ?
      WHERE
        id = ?
    SQL
  end

  def save
    if @id
      self.update
    else
      self.create
    end
  end

end

# ------------------------------------------------
# ------------------------------------------------
# ------------------------------------------------

class Question_follows

  attr_accessor :id, :user_id, :question_id
  
  def self.find_by_id(id)
    data = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT *
      FROM question_follows
      WHERE id = ?
    SQL
    Question_follows.new(data.first)
  end

  def self.followers_for_question_id(question_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT *
      FROM users
      JOIN question_follows ON users.id = question_follows.user_id
      WHERE question_id = ?
    SQL
    debugger
    data.map {|datum| Users.new(datum)}
  end

  def self.followed_questions_for_user_id(user_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT *
      FROM questions
      JOIN question_follows ON questions.id = question_follows.question_id
      WHERE question_follows.user_id = ?
    SQL
    data.map {|datum| Questions.new(datum)}
  end

  def self.most_followed_questions(n)
    data = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT *, COUNT(question_id) AS count
      FROM question_follows
      JOIN questions ON questions.id = question_follows.question_id
      GROUP BY question_id
      ORDER BY count DESC
      LIMIT ?
    SQL
    data.map {|datum| Questions.new(datum)}
  end

  def initialize(data)
    @id = data['id']
    @user_id = data['user_id']
    @question_id = data['question_id']
  end

end

# ------------------------------------------------
# ------------------------------------------------
# ------------------------------------------------

class Replies

  attr_accessor :id, :user_id, :question_id, :parent_id, :body

  def self.find_by_id(id)
    data = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT *
      FROM replies
      WHERE id = ?
    SQL
    return nil if data.empty?
    Replies.new(data.first)
  end

  def self.find_by_user_id(id)
    data = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT *
      FROM replies
      WHERE user_id = ?
    SQL
    data.map {|datum| Replies.new(datum)}
  end

  def self.find_by_question_id(id)
    data = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT *
      FROM replies
      WHERE question_id = ?
    SQL
    data.map {|datum| Replies.new(datum)}
  end

  def initialize(data)
    @id = data['id']
    @user_id = data['user_id']
    @question_id = data['question_id']
    @parent_id = data['parent_id']
    @body = data['body']
  end

  def author
    Users.find_by_id(self.user_id)
  end

  def question
    Questions.find_by_id(self.question_id)
  end

  def parent_reply
    Replies.find_by_id(self.parent_id)
  end

  def child_replies
    data = QuestionsDatabase.instance.execute(<<-SQL, self.id)
      SELECT *
      FROM replies
      WHERE parent_id = ?
    SQL
    data.map {|datum| Replies.new(datum)}
  end

  def create
    raise "#{self} already in database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, @user_id, @question_id, @parent_id, @body)
      INSERT INTO
        replies (user_id, question_id, parent_id, body)
      VALUES
        (?, ?, ?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, @user_id, @question_id, @parent_id, @body, @id)
      UPDATE
        replies
      SET
        user_id = ?, question_id = ?, parent_id = ?, body = ?
      WHERE
        id = ?
    SQL
  end

  def save
    if @id
      self.update
    else
      self.create
    end
  end

end

# ------------------------------------------------
# ------------------------------------------------
# ------------------------------------------------

class Question_likes

  attr_accessor :id, :user_id, :question_id

  def self.find_by_id(id)
    data = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT *
      FROM question_likes
      WHERE id = ?
    SQL
    Question_likes.new(data.first)
  end

  def initialize(data)
    @id = data['id']
    @user_id = data['user_id']
    @question_id = data['question_id']
  end

  def self.likers_for_question_id(question_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT *
      FROM question_likes
      WHERE question_id = ?
    SQL
    data.map {|datum| Users.find_by_id(datum['user_id'])}
  end

  def self.num_likes_for_question_id(question_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT COUNT(user_id) as count
      FROM question_likes
      WHERE question_id = ?
    SQL
    data.first["count"]
  end

  def self.liked_questions_for_user_id(user_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT *
      FROM question_likes
      WHERE user_id = ?
    SQL
    data.map {|datum| Questions.find_by_id(datum['question_id'])}
  end

  def self.most_liked_questions(n)
    data = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT *, COUNT(question_id) AS count
      FROM question_likes
      JOIN questions ON questions.id = question_likes.question_id
      GROUP BY question_id
      ORDER BY count DESC
      LIMIT ?
    SQL
    data.map {|datum| Questions.new(datum)}
  end
end
