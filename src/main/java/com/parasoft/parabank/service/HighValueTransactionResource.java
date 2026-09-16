package com.parasoft.parabank.service;

import java.math.BigDecimal;
import java.util.List;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import org.springframework.dao.EmptyResultDataAccessException;

import com.parasoft.parabank.domain.Transaction;
import com.parasoft.parabank.domain.logic.BankManager;

@Path("/accounts")
@Produces(MediaType.APPLICATION_JSON)
public class HighValueTransactionResource {
    private BankManager bankManager;

    @GET
    @Path("/{accountId}/transactions/highValue")
    @Operation(summary = "Get high-value transactions for an account", tags = { ParaBankServiceConstants.ACCOUNTS })
    public Response getHighValueTransactions(
        @Parameter(required = true) @PathParam("accountId") final int accountId,
        @Parameter(required = true) @QueryParam("threshold") final String threshold) {
        final BigDecimal parsedThreshold = parseThreshold(threshold);
        if (parsedThreshold == null) {
            return Response.status(Response.Status.BAD_REQUEST).build();
        }

        try {
            if (bankManager.getAccount(accountId) != null) {
                final List<Transaction> transactions =
                    bankManager.getHighValueTransactionsForAccount(accountId, parsedThreshold);
                return Response.ok(transactions).build();
            }
        } catch (final EmptyResultDataAccessException ex) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
        return Response.status(Response.Status.NOT_FOUND).build();
    }

    private BigDecimal parseThreshold(final String threshold) {
        if (threshold == null || threshold.isEmpty()) {
            return null;
        }
        try {
            return new BigDecimal(threshold);
        } catch (final NumberFormatException ex) {
            return null;
        }
    }

    public void setBankManager(final BankManager bankManager) {
        this.bankManager = bankManager;
    }
}
