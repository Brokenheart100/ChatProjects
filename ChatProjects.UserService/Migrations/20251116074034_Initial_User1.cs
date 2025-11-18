using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ChatProjects.UserService.Migrations
{
    /// <inheritdoc />
    public partial class Initial_User1 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Id",
                table: "UserProfiles");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Id",
                table: "UserProfiles",
                type: "text",
                nullable: true);
        }
    }
}
