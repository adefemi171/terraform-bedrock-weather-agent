import json
import requests
import logging
from functools import lru_cache
from aws_lambda_powertools import Metrics, Logger, Tracer


logger = Logger()
tracer = Tracer()
metrics = Metrics(namespace="WeatherService")

# Open-Meteo API URLs
GEOCODING_API_URL = "https://geocoding-api.open-meteo.com/v1/search"
WEATHER_API_URL = "https://api.open-meteo.com/v1/forecast"


def geocode_location(location):
    """Convert location name to latitude and longitude"""
    try:
        params = {
            'name': location,
            'count': 1,
            'language': 'en',
            'format': 'json'
        }
        response = requests.get(GEOCODING_API_URL, params=params)
        response.raise_for_status()
        data = response.json()
        
        if not data.get('results'):
            logger.warning(f"No geocoding results found for location: {location}")
            return None
        
        result = data['results'][0]
        return {
            'latitude': result['latitude'],
            'longitude': result['longitude'],
            'name': result['name'],
            'country': result.get('country', '')
        }
    except Exception as e:
        logger.error(f"Error geocoding location: {str(e)}")
        return None

def get_weather(location_info):
    """Fetch weather data for given coordinates"""
    try:
        params = {
            'latitude': location_info['latitude'],
            'longitude': location_info['longitude'],
            'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,rain,showers,snowfall,weather_code,cloud_cover,wind_speed_10m',
            'timezone': 'auto',
            'forecast_days': 1
        }
        response = requests.get(WEATHER_API_URL, params=params)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        logger.error(f"Error fetching weather data: {str(e)}")
        return None

def interpret_weather_code(code):
    """Convert Open-Meteo weather code to descriptive text"""
    # Weather codes from Open-Meteo documentation
    weather_codes = {
        0: "clear sky",
        1: "mainly clear",
        2: "partly cloudy",
        3: "overcast",
        45: "fog",
        48: "rime fog",
        51: "light drizzle",
        53: "moderate drizzle",
        55: "dense drizzle",
        56: "light freezing drizzle",
        57: "dense freezing drizzle",
        61: "slight rain",
        63: "moderate rain",
        65: "heavy rain",
        66: "light freezing rain",
        67: "heavy freezing rain",
        71: "slight snow fall",
        73: "moderate snow fall",
        75: "heavy snow fall",
        77: "snow grains",
        80: "slight rain showers",
        81: "moderate rain showers",
        82: "violent rain showers",
        85: "slight snow showers",
        86: "heavy snow showers",
        95: "thunderstorm",
        96: "thunderstorm with slight hail",
        99: "thunderstorm with heavy hail"
    }
    return weather_codes.get(code, "unknown conditions")

def suggest_clothing(weather_data, location_info):
    """Suggest clothing based on weather conditions"""
    if not weather_data:
        return "I couldn't get weather information. Please try again later."
    
    try:
        current = weather_data['current']
        
        temp_c = current['temperature_2m']
        apparent_temp = current['apparent_temperature']
        weather_code = current['weather_code']
        is_day = current['is_day']
        humidity = current['relative_humidity_2m']
        wind_kph = current['wind_speed_10m'] * 3.6  # Convert m/s to km/h
        precipitation = current['precipitation']
        snowfall = current['snowfall']
        
        condition = interpret_weather_code(weather_code)
        location_name = f"{location_info['name']}, {location_info['country']}"
        
        if temp_c > 30:
            base_clothing = "lightweight, breathable clothing like shorts, t-shirts, and tank tops"
            accessories = "a hat, sunglasses, and sunscreen"
        elif temp_c > 25:
            base_clothing = "light clothing like shorts or light pants and short-sleeved shirts"
            accessories = "sunglasses and sunscreen"
        elif temp_c > 20:
            base_clothing = "comfortable clothing like jeans or light pants and a t-shirt or light sweater"
            accessories = "maybe a light jacket for the evening"
        elif temp_c > 15:
            base_clothing = "layers like jeans, a t-shirt, and a light jacket or sweater"
            accessories = "a light scarf if it's windy"
        elif temp_c > 10:
            base_clothing = "warmer layers like jeans, a long-sleeved shirt, and a jacket"
            accessories = "a scarf and maybe a light hat"
        elif temp_c > 5:
            base_clothing = "warm clothing like jeans or warm pants, a sweater, and a jacket"
            accessories = "a scarf, gloves, and a hat"
        elif temp_c > 0:
            base_clothing = "warm layers including thermal underwear, jeans or warm pants, a sweater, and a warm jacket"
            accessories = "a warm scarf, gloves, and a hat"
        else:
            base_clothing = "very warm layers including thermal underwear, warm pants, a sweater, and a heavy winter coat"
            accessories = "a warm scarf, insulated gloves, and a warm hat"
        
        if precipitation > 0 and snowfall == 0:
            if precipitation > 4:
                weather_specific = "It's raining heavily, so wear a waterproof jacket or raincoat, waterproof shoes, and bring an umbrella."
            elif precipitation > 1:
                weather_specific = "There's moderate rain, so bring a waterproof jacket or raincoat and an umbrella."
            else:
                weather_specific = "There's light rain, so consider bringing a light raincoat or umbrella."
        elif snowfall > 0:
            if snowfall > 5:
                weather_specific = "There's heavy snowfall, so wear waterproof and insulated boots, a warm waterproof jacket, and consider snow pants."
            else:
                weather_specific = "There's some snow, so wear waterproof boots and a warm waterproof jacket."
        elif 'fog' in condition:
            weather_specific = "It's foggy, so wear bright or reflective clothing for visibility."
        elif 'clear' in condition and is_day:
            weather_specific = "It's sunny, so don't forget sun protection!"
        elif 'cloud' in condition or 'overcast' in condition:
            weather_specific = "The weather might change, so consider bringing an extra layer."
        elif 'thunder' in condition:
            weather_specific = "There's a thunderstorm, so stay indoors if possible. If you must go out, wear a waterproof jacket with a hood and avoid carrying metal objects."
        else:
            weather_specific = ""
        
        if wind_kph > 30:
            wind_advice = "It's quite windy, so wear clothing that won't catch the wind and consider a windbreaker."
        elif wind_kph > 20:
            wind_advice = "There's a moderate breeze, so a windbreaker might be comfortable."
        else:
            wind_advice = ""

        if humidity > 80 and temp_c > 20:
            humidity_advice = "It's humid, so wear breathable, moisture-wicking fabrics."
        else:
            humidity_advice = ""
        
        temp_difference = apparent_temp - temp_c
        if abs(temp_difference) > 3:
            if temp_difference > 0:
                feel_advice = f"It feels warmer than the actual temperature (feels like {apparent_temp}°C), so you might want to dress a bit lighter."
            else:
                feel_advice = f"It feels colder than the actual temperature (feels like {apparent_temp}°C), so you might want to add an extra layer."
        else:
            feel_advice = ""
        

        advice_parts = [
            f"For the current weather in {location_name} ({temp_c}°C, {condition}), I recommend wearing {base_clothing}.",
            f"For accessories, consider {accessories}.",
            weather_specific,
            wind_advice,
            humidity_advice,
            feel_advice
        ]
        
        return " ".join(filter(None, advice_parts))
        
    except Exception as e:
        logger.error(f"Error generating clothing suggestion: {str(e)}")
        return "I'm having trouble analyzing the weather data. Please try again."

def lambda_handler(event, context):
    """Lambda function handler for Bedrock agent integration"""
    logger.info(f"Received event: {json.dumps(event)}")
    
    try:
        location = None
        
        if 'parameters' in event:
            for param in event.get('parameters', []):
                if param['name'] == 'location':
                    location = param['value']
                    break
        
        if not location and 'requestBody' in event:
            properties = event['requestBody']['content'].get('application/json', {}).get('properties', [])
            for prop in properties:
                if prop['name'] == 'location':
                    location = prop['value']
                    break
        
        if not location:
            response_message = "I need a location to provide clothing suggestions. Please specify a city or region."
        else:
            location_info = geocode_location(location)
            
            if not location_info:
                response_message = f"I couldn't find the location '{location}'. Please try a different city or region."
            else:
                weather_data = get_weather(location_info)
                response_message = suggest_clothing(weather_data, location_info)
        
        
        if 'apiPath' in event:
            action_response = {
                'actionGroup': event['actionGroup'],
                'apiPath': event['apiPath'],
                'httpMethod': event['httpMethod'],
                'httpStatusCode': 200,
                'responseBody': {
                    'application/json': {
                        'body': json.dumps({
                            'suggestion': response_message,
                            'location': location
                        })
                    }
                }
            }
        else:
            action_response = {
                'actionGroup': event['actionGroup'],
                'function': event['function'],
                'functionResponse': {
                    'responseBody': {
                        'TEXT': {
                            'body': json.dumps({
                                'suggestion': response_message,
                                'location': location
                            })
                        }
                    }
                }
            }
        

        api_response = {
            'messageVersion': '1.0',
            'response': action_response,
            'sessionAttributes': event.get('sessionAttributes', {}),
            'promptSessionAttributes': event.get('promptSessionAttributes', {})
        }
        
        logger.info(f"Returning response: {json.dumps(api_response)}")
        return api_response
        
    except Exception as e:
        logger.error(f"Error in lambda_handler: {str(e)}")
        

        error_response = {
            'messageVersion': '1.0',
            'response': {
                'actionGroup': event.get('actionGroup', 'ClothingSuggestion'),
                'function': event.get('function', 'suggestClothing'),
                'functionResponse': {
                    'responseState': 'FAILURE',
                    'responseBody': {
                        'TEXT': {
                            'body': json.dumps({
                                'error': f"An error occurred: {str(e)}"
                            })
                        }
                    }
                }
            },
            'sessionAttributes': event.get('sessionAttributes', {}),
            'promptSessionAttributes': event.get('promptSessionAttributes', {})
        }
        
        return error_response

