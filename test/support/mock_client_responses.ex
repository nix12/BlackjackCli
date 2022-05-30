defmodule BlackjackCli.MockClientResponses do
  def registration_success_resp do
    "{\"token\":\"token\",\"user\":{\"inserted_at\":\"2022-05-01T22:58:06\",\"password_hash\":\"$2b$12$vvJ.QX8wFQJ/bfeOTlYKNeqEy70hiCe4Q6URhMewA1FO12pQH3oKm\",\"updated_at\":\"2022-05-01T22:58:06\",\"username\":\"username\",\"uuid\":\"uuid\"}}"
  end

  def registration_fail_resp do
    "{\"errors\":\"username has already been taken.\"}"
  end

  def login_success_resp do
    "{\"token\":\"token\",\"user\":{\"inserted_at\":\"2022-05-01T22:58:06\",\"password_hash\":\"$2b$12$vvJ.QX8wFQJ/bfeOTlYKNeqEy70hiCe4Q6URhMewA1FO12pQH3oKm\",\"updated_at\":\"2022-05-01T22:58:06\",\"username\":\"username\",\"uuid\":\"uuid\"}}"
  end

  def login_password_fail_resp do
    "{\"errors\":\"invalid password\"}"
  end

  def login_credentials_fail_resp do
    "{\"errors\":\"invalid credentials\"}"
  end
end
