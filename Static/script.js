// api url
const api_url = "";

function returnCounter(){
getapi(api_url).then(apiresult =>{
let CounterInt = apiresult;

let CounterintasString = `${CounterInt}`;

//Return Message
let CounterMessage = (`${CounterintasString}`);
//alert(CounterMessage);
const Counterelement = document.querySelector('.Counter');
//document.getElementById("Counter").textContent = CounterMessage;
document.getElementById("Counter").textContent = CounterInt;
return CounterMessage;
});
}

// Defining async function
async function getapi(url) {
	
	// Storing response
	const response = await fetch(url);
	const names = await response.json();
	
	//var data = JSON.parse(response);
	var data = JSON.parse(names);
	//alert(data.amount);
	var apiAmount = parseInt(data.amount);
	//alert(apiAmount);
	return(apiAmount);
}

returnCounter()

