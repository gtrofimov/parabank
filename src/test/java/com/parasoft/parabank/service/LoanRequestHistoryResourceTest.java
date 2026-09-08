package com.parasoft.parabank.service;

import static org.junit.Assert.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import org.junit.Test;
import org.springframework.dao.EmptyResultDataAccessException;

import com.parasoft.parabank.domain.Customer;
import com.parasoft.parabank.domain.logic.BankManager;

import jakarta.ws.rs.core.Response;

public class LoanRequestHistoryResourceTest {
    @Test
    public void testGetLoanRequestsReturnsEmptyHistory() {
        final LoanRequestHistoryResource resource = new LoanRequestHistoryResource();
        final BankManager bankManager = mock(BankManager.class);
        when(bankManager.getCustomer(12212)).thenReturn(new Customer());
        resource.setBankManager(bankManager);

        assertEquals(Response.Status.OK.getStatusCode(), resource.getLoanRequests(12212).getStatus());
    }

    @Test
    public void testGetLoanRequestsForUnknownCustomer() {
        final LoanRequestHistoryResource resource = new LoanRequestHistoryResource();
        final BankManager bankManager = mock(BankManager.class);
        when(bankManager.getCustomer(-1)).thenThrow(new EmptyResultDataAccessException(1));
        resource.setBankManager(bankManager);

        assertEquals(Response.Status.NOT_FOUND.getStatusCode(), resource.getLoanRequests(-1).getStatus());
    }
}