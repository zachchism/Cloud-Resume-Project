/// <reference types="Cypress" />
describe('My First Test', () => {
  it('finds the title "type"', () => {
    cy.visit(Cypress.env('DEV_URL'),
    cy.wait(2000),
    cy.get('#Counter').then(($counter) => {
      let value = parseInt($counter.text());
      cy.visit(Cypress.env('DEV_URL'),
      cy.wait(2000),
      cy.get('#Counter').then(($counter2) =>{
      let value2 = parseInt($counter2.text());
      expect(value2).to.eq(value + 1);
      })
    })
  })
})
