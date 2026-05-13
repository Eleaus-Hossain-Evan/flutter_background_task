# Refactor Visual Overview

Below is a high‑level diagram of the proposed folder structure and how the main layers map to SOLID principles.

```mermaid
flowchart TD
    subgraph lib["lib/"]
        direction TB
        subgraph core["core/"]
            direction TB
            subgraph background["background/"]
                FG["foreground_service_manager.dart"]
                FH["foreground_task_handler.dart"]
            end
            subgraph notifications["notifications/"]
                LN["local_notification_service.dart"]
                NS["notification_service.dart"]
            end
            subgraph socket["socket/"]
                SS["socket_service.dart"]
                SE["socket_event.dart"]
            end
        end
        subgraph home["home/"]
            HS["home_screen.dart"]
        end
        subgraph providers["providers/"]
            OP["online_provider.dart"]
        end
        subgraph models["models/"]
            NM["notification_model.dart"]
        end
    end
    
    %% SOLID mapping
    classDef singleResponsibility fill:#f9f,stroke:#333,stroke-width:2px;
    classDef openClose fill:#bbf,stroke:#333,stroke-width:2px;
    classDef liskov fill:#bfb,stroke:#333,stroke-width:2px;
    classDef interfaceSeg fill:#ffb,stroke:#333,stroke-width:2px;
    classDef dependencyInj fill:#fb9,stroke:#333,stroke-width:2px;
    
    FG:::singleResponsibility
    FH:::singleResponsibility
    LN:::singleResponsibility
    SS:::singleResponsibility
    OP:::openClose
    NM:::openClose
    
    SS:::interfaceSeg
    OP:::dependencyInj
    FN:::dependencyInj
```

* **Single Responsibility** – each file encapsulates one cohesive responsibility.
* **Open/Closed** – providers and services expose interfaces (`ISocketService`) that can be extended without modification.
* **Liskov Substitution** – `SocketService` implements `ISocketService`.
* **Interface Segregation** – small focused interfaces (`ISocketService`).
* **Dependency Inversion** – high‑level modules (`Online` provider) depend on abstractions rather than concrete implementations.

You can view the diagram directly in this markdown or open the file in any markdown viewer that supports Mermaid.
