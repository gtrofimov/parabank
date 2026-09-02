package com.parasoft.parabank.service;

import java.util.List;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

import com.parasoft.parabank.domain.LoanRequestHistory;
import com.parasoft.parabank.domain.logic.BankManager;

@Path("/customers")
@Produces(MediaType.APPLICATION_JSON)
public class LoanRequestHistoryResource {
    private BankManager bankManager;

    @GET
    @Path("/{customerId}/loanRequests")
    @Operation(summary = "Get customer loan request history", tags = { ParaBankServiceConstants.LOANS })
    public List<LoanRequestHistory> getLoanRequests(
        @Parameter(required = true) @PathParam("customerId") final int customerId) {
        if (bankManager.getCustomer(customerId) == null) {
            throw new NotFoundException();
        }
        return bankManager.getLoanRequestsForCustomer(customerId);
    }

    public void setBankManager(final BankManager bankManager) {
        this.bankManager = bankManager;
    }
}