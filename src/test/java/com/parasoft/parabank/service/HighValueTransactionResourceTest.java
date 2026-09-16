package com.parasoft.parabank.service;

import static org.junit.Assert.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.Collections;
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
        final Transaction transaction = new Transaction();
        transaction.setId(1);
        transaction.setAccountId(12345);
        transaction.setAmount(new BigDecimal("500.00"));
        when(bankManager.getHighValueTransactionsForAccount(12345, new BigDecimal("100")))
            .thenReturn(Arrays.asList(transaction));
        resource.setBankManager(bankManager);

        final Response response = resource.getHighValueTransactions(12345, "100");
        assertEquals(Response.Status.OK.getStatusCode(), response.getStatus());
        @SuppressWarnings("unchecked")
        final List<Transaction> body = (List<Transaction>) response.getEntity();
        assertEquals(1, body.size());
    }

    @Test
    public void testGetHighValueTransactionsReturnsEmptyArray() {
        final HighValueTransactionResource resource = new HighValueTransactionResource();
        final BankManager bankManager = mock(BankManager.class);
        when(bankManager.getAccount(12345)).thenReturn(new Account());
        when(bankManager.getHighValueTransactionsForAccount(12345, new BigDecimal("100")))
            .thenReturn(Collections.<Transaction>emptyList());
        resource.setBankManager(bankManager);

        final Response response = resource.getHighValueTransactions(12345, "100");
        assertEquals(Response.Status.OK.getStatusCode(), response.getStatus());
        @SuppressWarnings("unchecked")
        final List<Transaction> body = (List<Transaction>) response.getEntity();
        assertEquals(0, body.size());
    }

    @Test
    public void testGetHighValueTransactionsMissingThresholdReturns400() {
        final HighValueTransactionResource resource = new HighValueTransactionResource();
        final BankManager bankManager = mock(BankManager.class);
        resource.setBankManager(bankManager);

        final Response response = resource.getHighValueTransactions(12345, null);
        assertEquals(Response.Status.BAD_REQUEST.getStatusCode(), response.getStatus());
    }

    @Test
    public void testGetHighValueTransactionsInvalidThresholdReturns400() {
        final HighValueTransactionResource resource = new HighValueTransactionResource();
        final BankManager bankManager = mock(BankManager.class);
        resource.setBankManager(bankManager);

        final Response response = resource.getHighValueTransactions(12345, "not-a-number");
        assertEquals(Response.Status.BAD_REQUEST.getStatusCode(), response.getStatus());
    }

    @Test
    public void testGetHighValueTransactionsUnknownAccountReturns404() {
        final HighValueTransactionResource resource = new HighValueTransactionResource();
        final BankManager bankManager = mock(BankManager.class);
        when(bankManager.getAccount(-1)).thenThrow(new EmptyResultDataAccessException(1));
        resource.setBankManager(bankManager);

        final Response response = resource.getHighValueTransactions(-1, "100");
        assertEquals(Response.Status.NOT_FOUND.getStatusCode(), response.getStatus());
    }
}
