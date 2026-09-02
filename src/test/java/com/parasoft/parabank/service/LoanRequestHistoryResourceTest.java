package com.parasoft.parabank.service;

import static org.junit.Assert.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import org.junit.Test;

import com.parasoft.parabank.domain.Customer;
import com.parasoft.parabank.domain.logic.BankManager;

import jakarta.ws.rs.NotFoundException;

public class LoanRequestHistoryResourceTest {
    @Test
    public void testGetLoanRequestsReturnsEmptyHistory() {
        final LoanRequestHistoryResource resource = new LoanRequestHistoryResource();
        final BankManager bankManager = mock(BankManager.class);
        when(bankManager.getCustomer(12212)).thenReturn(new Customer());
        resource.setBankManager(bankManager);

        assertEquals(0, resource.getLoanRequests(12212).size());
    }

    @Test(expected = NotFoundException.class)
    public void testGetLoanRequestsForUnknownCustomer() {
        final LoanRequestHistoryResource resource = new LoanRequestHistoryResource();
        resource.setBankManager(mock(BankManager.class));

        resource.getLoanRequests(-1);
    }
}