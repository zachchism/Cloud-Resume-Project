/// <reference types="Cypress" />
describe('WebApp Function Test', () => {  

  it('Gets value of counter',
  {
retries:	{
    runMode: 3,
    openMode: 3,
			},
  },
  () => {
	//Define intercept for backend API call
	cy.intercept('GET', 'webapp').as('counterRequest')
	//Get value of counter on visit 1
	cy.visit(Cypress.env('DEV_URL')), 								  															   
    cy.wait('@counterRequest').then(($counter) => {
		expect($counter).to.not.be.null
    cy.get('#Counter').then(($counter) => {
      const value = parseInt($counter.text())
	//Get value of counter on visit 2
	cy.visit(Cypress.env('DEV_URL')), 

    cy.wait('@counterRequest').then(($counter2) => {
		expect($counter2).to.not.be.null
    cy.get('#Counter').then(($counter2) => {
      const value2 = parseInt($counter2.text())
	//Verify that counter changed between visits as expected  	  
	expect(value2).to.eq(value + 1)
      })
    })	
  })
})
})
})