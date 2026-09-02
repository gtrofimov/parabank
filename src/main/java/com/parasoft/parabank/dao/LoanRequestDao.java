package com.parasoft.parabank.dao;

import java.util.List;

import com.parasoft.parabank.domain.LoanRequestHistory;

public interface LoanRequestDao {
    int createLoanRequest(LoanRequestHistory loanRequest);

    void updateLoanRequest(LoanRequestHistory loanRequest);

    List<LoanRequestHistory> getLoanRequestsForCustomer(int customerId);
}