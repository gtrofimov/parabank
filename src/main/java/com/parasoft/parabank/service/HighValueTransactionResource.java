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
    @Operation(summary = "Get high-value transactions for an account", tags = {
        ParaBankServiceConstants.TRANSACTIONS })
    public Response getHighValueTransactions(
        @Parameter(description = ParaBankServiceConstants.CUSTOMER_ACCOUNT_FETCH_DESC,
            required = true) @PathParam(ParaBankServiceConstants.ACCOUNT_ID) final int accountId,
        @Parameter(description = ParaBankServiceConstants.AMOUNT_DESC,
            required = true) @QueryParam("threshold") final String threshold) {
        final BigDecimal parsedThreshold;
        try {
            parsedThreshold = new BigDecimal(threshold);
        } catch (final NumberFormatException | NullPointerException ex) {
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

    public void setBankManager(final BankManager bankManager) {
        this.bankManager = bankManager;
    }
}
