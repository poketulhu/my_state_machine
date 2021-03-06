require_relative 'my_aasm/my_aasm'

class Article
  include MyAASM
  attr_accessor :title, :body, :description

  def initialize(title: 'Some title', body: 'Some body', description: 'Some description')
    @title = title
    @body = body
    @description = description
  end

  def self.article_correct
    rand(10) > 5 ? true : false
  end

  my_aasm do
    state :init
    state :created
    state :accepted
    state :not_accepted
    state :edited
    state :published
    state :deleted

    event :create, after: :send_creation_information do
      transitions from: :init, to: :created
    end

    event :check do
      transitions from: [:created, :edited], to: :accepted, if: :article_correct
      transitions from: [:created, :edited], to: :not_accepted
    end

    event :publish do
      transitions from: :accepted, to: :published
    end

    event :edit do
      transitions from: :not_accepted, to: :edited
    end

    event :delete do
      transitions from: [:created, :published], to: :deleted
    end
  end

  def send_creation_information
    p "Article is created"
  end
end