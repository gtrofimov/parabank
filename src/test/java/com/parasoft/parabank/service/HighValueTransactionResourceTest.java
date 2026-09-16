package com.parasoft.parabank.service;

import static org.junit.Assert.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

import org.junit.Test;
import org.springframework.dao.EmptyResultDataAccessException;

import com.parasoft.parabank.domain.Account;
import com.parasoft.parabank.domain.Transaction;
import com.parasoft.parabank.domain.logic.BankManager;

import jakarta.ws.rs.core.Response;

public class HighValueTransactionResourceTest {
    @Test
    public void testGetHighValueTransactionsReturnsMatches() {
        final HighValueTransactionResource resource = new HighValueTransactionResource();
        final BankManager bankManager = mock(BankManager.class);
        when(bankManager.getAccount(12345)).thenReturn(new Account());
        final List<Transaction> transactions = new ArrayList<>();
        transactions.add(new Transaction());
        when(bankManager.getHighValueTransactionsForAccount(12345, new BigDecimal("1000")))
            .thenReturn(transactions);
        resource.setBankManager(bankManager);

        final Response response = resource.getHighValueTransactions(12345, "1000");
        assertEquals(Response.Status.OK.getStatusCode(), response.getStatus());
        assertEquals(1, ((List<?>) response.getEntity()).size());
    }

    @Test
    public void testGetHighValueTransactionsReturnsEmptyArray() {
        final HighValueTransactionResource resource = new HighValueTransactionResource();
        final BankManager bankManager = mock(BankManager.class);
        when(bankManager.getAccount(12345)).thenReturn(new Account());
        when(bankManager.getHighValueTransactionsForAccount(12345, new BigDecimal("1000")))
            .thenReturn(new ArrayList<Transaction>());
        resource.setBankManager(bankManager);

        final Response response = resource.getHighValueTransactions(12345, "1000");
        assertEquals(Response.Status.OK.getStatusCode(), response.getStatus());
        assertEquals(0, ((List<?>) response.getEntity()).size());
    }

    @Test
    public void testGetHighValueTransactionsForUnknownAccount() {
        final HighValueTransactionResource resource = new HighValueTransactionResource();
        final BankManager bankManager = mock(BankManager.class);
        when(bankManager.getAccount(-1)).thenThrow(new EmptyResultDataAccessException(1));
        resource.setBankManager(bankManager);

        final Response response = resource.getHighValueTransactions(-1, "1000");
        assertEquals(Response.Status.NOT_FOUND.getStatusCode(), response.getStatus());
    }

    @Test
    public void testGetHighValueTransactionsMissingThreshold() {
        final HighValueTransactionResource resource = new HighValueTransactionResource();
        final BankManager bankManager = mock(BankManager.class);
        resource.setBankManager(bankManager);

        final Response response = resource.getHighValueTransactions(12345, null);
        assertEquals(Response.Status.BAD_REQUEST.getStatusCode(), response.getStatus());
    }

    @Test
    public void testGetHighValueTransactionsInvalidThreshold() {
        final HighValueTransactionResource resource = new HighValueTransactionResource();
        final BankManager bankManager = mock(BankManager.class);
        resource.setBankManager(bankManager);

        final Response response = resource.getHighValueTransactions(12345, "not-a-number");
        assertEquals(Response.Status.BAD_REQUEST.getStatusCode(), response.getStatus());
    }
}
