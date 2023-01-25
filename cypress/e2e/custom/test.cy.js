/// <reference types="Cypress" />
describe('My First Test', () => {
	
	context('Actions', () => {
  beforeEach(() => {
    cy.visit(Cypress.env('DEV_URL'))
  })
  
  it('Gets initial value of counter', () => {
    cy.wait(2000)
    cy.get('#Counter').then(($counter) => {
      let value = parseInt($counter.text())
      })
    })
	
  it('Gets final value of counter', () => {
    cy.wait(2000)
    cy.get('#Counter').then(($counter2) => {
    let value2 = parseInt($counter2.text())
	expect(value2).to.eq(value + 1)
      })
    })	
  })
})
