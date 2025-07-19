use clap::{Parser, Subcommand};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Agent {
    id: String,
    role: String,
    performance_score: f32,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
enum TaskStatus {
    Pending,
    InProgress,
    Completed,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Task {
    id: String,
    description: String,
    assigned_agent_id: Option<String>,
    status: TaskStatus,
}

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Create a new agent
    CreateAgent {
        /// The role of the agent
        #[arg(short, long)]
        role: String,
    },
    /// List all agents
    ListAgents,
    /// Create a new task
    CreateTask {
        /// The description of the task
        #[arg(short, long)]
        description: String,
    },
    /// List all tasks
    ListTasks,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let cli = Cli::parse();

    // In-memory storage
    let mut agents: Vec<Agent> = Vec::new();
    let mut tasks: Vec<Task> = Vec::new();

    match &cli.command {
        Commands::CreateAgent { role } => {
            let new_agent = Agent {
                id: Uuid::new_v4().to_string(),
                role: role.clone(),
                performance_score: 0.0,
            };
            println!("Created agent: {:?}", new_agent);
            // In a real application, you would save this to a file or database.
            // For now, we just print it.
        }
        Commands::ListAgents => {
            // In a real application, you would load this from a file or database.
            println!("Listing all agents: {:?}", agents);
        }
        Commands::CreateTask { description } => {
            let new_task = Task {
                id: Uuid::new_v4().to_string(),
                description: description.clone(),
                assigned_agent_id: None,
                status: TaskStatus::Pending,
            };
            println!("Created task: {:?}", new_task);
            // In a real application, you would save this to a file or database.
        }
        Commands::ListTasks => {
            // In a real application, you would load this from a file or database.
            println!("Listing all tasks: {:?}", tasks);
        }
    }

    Ok(())
}
