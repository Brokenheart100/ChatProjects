namespace ChatProjects.SearchService.Dtos;
public class MessageIndexDto
{
    [System.Text.Json.Serialization.JsonPropertyName("id")]
    public string Id { get; set; } = "";

    [System.Text.Json.Serialization.JsonPropertyName("sender_id")]
    public string SenderId { get; set; } = "";

    [System.Text.Json.Serialization.JsonPropertyName("content")]
    public string Content { get; set; } = "";

    [System.Text.Json.Serialization.JsonPropertyName("sent_at")]
    public long SentAt { get; set; }
}