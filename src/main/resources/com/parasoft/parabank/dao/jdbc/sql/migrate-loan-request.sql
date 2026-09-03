CREATE TABLE IF NOT EXISTS LoanRequest (
  id INTEGER NOT NULL PRIMARY KEY,
  customer_id INTEGER NOT NULL,
  request_date DATE NOT NULL,
  available_funds DECIMAL(19,4) NOT NULL,
  loan_amount DECIMAL(19,4) NOT NULL,
  down_payment DECIMAL(19,4) NOT NULL,
  approved BOOLEAN,
  response_date DATE,
  loan_account_id INTEGER,
  provider_name VARCHAR(4000),
  message VARCHAR(4000),
  status VARCHAR(10) NOT NULL,

  FOREIGN KEY (customer_id) REFERENCES Customer(id),
  FOREIGN KEY (loan_account_id) REFERENCES Account(id)
);