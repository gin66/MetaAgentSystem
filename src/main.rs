use dotenvy::dotenv;
use openai_rust::chat::{ChatArguments, Message as OpenAiMessage};
use openai_rust::Client as OpenAiClient;
use rand::Rng;
use reqwest::Client as ReqwestClient;
use schemars::{schema_for, JsonSchema};
use serde::{Deserialize, Serialize};
use std::env;
use validator::Validate;

#[derive(Serialize, Deserialize, Debug, Validate, JsonSchema)]
struct MyData {
    #[validate(length(min = 1))]
    name: String,
    #[validate(length(min = 1))]
    value: String,
}

#[derive(Serialize, Deserialize, Debug)]
struct OllamaMessage {
    role: String,
    content: String,
}

#[derive(Serialize)]
struct OllamaRequest {
    model: String,
    messages: Vec<OllamaMessage>,
    stream: bool,
}

#[derive(Deserialize, Debug)]
struct OllamaResponse {
    message: OllamaMessage,
}

async fn request_openai(
    api_key: &str,
    system_prompt: &str,
    user_prompt: &str,
) -> Result<String, Box<dyn std::error::Error>> {
    let client = OpenAiClient::new(api_key);
    let args = ChatArguments::new(
        "gpt-3.5-turbo",
        vec![
            OpenAiMessage {
                role: "system".to_owned(),
                content: system_prompt.to_owned(),
            },
            OpenAiMessage {
                role: "user".to_owned(),
                content: user_prompt.to_owned(),
            },
        ],
    );
    let res = client.create_chat(args).await?;
    Ok(res.choices.get(0).unwrap().message.content.clone())
}

async fn request_ollama(
    system_prompt: &str,
    user_prompt: &str,
) -> Result<String, Box<dyn std::error::Error>> {
    let client = ReqwestClient::new();
    let ollama_url = "http://localhost:11434/api/chat";
    let request_payload = OllamaRequest {
        model: "mistral-small3.2:latest".to_string(),
        messages: vec![
            OllamaMessage {
                role: "system".to_string(),
                content: system_prompt.to_string(),
            },
            OllamaMessage {
                role: "user".to_string(),
                content: user_prompt.to_string(),
            },
        ],
        stream: false,
    };

    let res = client
        .post(ollama_url)
        .json(&request_payload)
        .send()
        .await?;

    let ollama_response = res.json::<OllamaResponse>().await?;
    let content = ollama_response.message.content.trim();
    let json_content = content
        .trim_start_matches("```json")
        .trim_start_matches("```")
        .trim_end_matches("```")
        .trim();
    Ok(json_content.to_string())
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    dotenv().ok();

    let schema = schema_for!(MyData);
    let schema_str = serde_json::to_string_pretty(&schema).unwrap();

    let system_prompt = format!(
        "You are a helpful assistant that provides structured JSON output. \
        The JSON object must conform to the following JSON Schema: \n\n{}",
        schema_str
    );
    let random_number = rand::thread_rng().gen_range(1..=1000);
    let user_prompt = format!(
        "Generate a JSON object with a name and a value. Include the number {} in the value.",
        random_number
    );

    let api_key = env::var("OPENAI_API_KEY").expect("OPENAI_API_KEY not set");

    let response_content = match request_openai(&api_key, &system_prompt, &user_prompt).await {
        Ok(content) => content,
        Err(e) => {
            if e.to_string().contains("quota") {
                println!("OpenAI quota exceeded, falling back to Ollama.");
                request_ollama(&system_prompt, &user_prompt).await?
            } else {
                return Err(e);
            }
        }
    };

    println!("{}", response_content);

    let json_response: MyData = serde_json::from_str(&response_content)?;
    json_response.validate()?;
    println!("{:?}", json_response);

    Ok(())
}
